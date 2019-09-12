import std.stdio;
import value;
import locals;

version = LOCALS_ARE_LEVEL;

version (LOCALS_ARE_AA) {
    alias LocalLevel = Value[string];
}
version (LOCALS_ARE_LEVEL) {
    alias LocalLevel = Level;
}
version (LOCALS_ARE_FLAT_LEVEL) {
    alias LocalLevel = FlatLevel;
}

LocalLevel createLocalLevel() {
    version (LOCALS_ARE_AA) {
        return null;
    }
    version (LOCALS_ARE_LEVEL) {
        return LocalLevel();
    }
    version (LOCALS_ARE_FLAT_LEVEL) {
        return LocalLevel();
    }
}

struct FlatLevel {
    size_t[] lts = [0];
    size_t[] gts = [0];
    Value[] vals = [Value()];
    string[] strs = [""];
    Value* opBinaryRight(string op)(ref string test) {
        static if (op == "in") {
            ulong place = 0;
            before:
            string str = strs[place];
            size_t slen = str.length;
            size_t tlen = test.length;
            if (slen != tlen) {
                if (slen < tlen) {
                    place = lts[place];
                }
                else {
                    place = gts[place];
                }
                if (place == 0) {
                    return null;
                }
                goto before;
            }
            foreach (i; 0..slen) {
                char sc = str[i];
                char tc = test[i];
                if (sc != tc) {
                    if (sc < tc) {
                        place = lts[place];
                    }
                    else {
                        place = gts[place];
                    }
                    if (place == 0) {
                        return null;
                    }
                    goto before;
                }
            }
            return &vals[place];
        }
    }
    void setNode(bool check=true)(size_t where, Value val, string test) {
        static if (check) {
            if (strs[where] == "") {
                strs[where] = test;
                lts[where] = strs.length;
                strs ~= "";
                lts ~= 0;
                gts ~= 0;
                vals ~= Value();
                gts[where] = strs.length;
                strs ~= "";
                lts ~= 0;
                gts ~= 0;
                vals ~= Value();
            }
        }
        static if (!check) {
            strs[where] = test;
            lts[where] = strs.length;
            strs ~= "";
            lts ~= 0;
            gts ~= 0;
            vals ~= Value();
            gts[where] = strs.length;
            strs ~= "";
            lts ~= 0;
            gts ~= 0;
            vals ~= Value();
        }
        vals[where] = val;
    }
    void opIndexAssign(Value aval, string test) {
        size_t where = 0;
        begin:
        string here = strs[where];
        if (here == "") {
            setNode!false(where, aval, test);
            return;           
        }
        int cval = 0;
        if (test.length < here.length) {
            where = gts[where];
            goto begin;
        }
        if (test.length > here.length) {
            where = lts[where];
            goto begin;
        }
        foreach (i; 0..test.length) {
            char ac = test[i];
            char bc = here[i];
            if (ac < bc) {
                where = gts[where];
                goto begin;
            }
            if (ac > bc) {
                where = lts[where];
                goto begin;
            }
        }
        setNode(where, aval, test);
    }
}

struct Level {
    Level* less = null;
    Level* greater = null;
    Value val;
    string str;
    this(string s, Value v) {
        val = v;
        str = s;
    }
    Value* opBinaryRight(string op)(ref string test) {
        static if (op == "in") {
            Level* tobj = &this;
            before:
            size_t slen = tobj.str.length;
            size_t tlen = test.length;
            if (slen != tlen) {
                Level* ret = tobj.less;
                if (slen > tlen) {
                    ret = tobj.greater;
                }
                if (ret is null) {
                    return null;
                }
                tobj = ret;
                goto before;
            }
            foreach (i; 0..slen) {
                char sc = tobj.str[i];
                char tc = test[i];
                if (sc != tc) {
                    Level* ret = tobj.less;
                    if (sc > tc) {
                        ret = tobj.greater;
                    }
                    if (ret is null) {
                        return null;
                    }
                    tobj = ret;
                    goto before;
                }
            }
            return &tobj.val;
        }
    } 
    void opIndexAssign(Value aval, string test) {
        Level* tobj = &this;
        before:
        size_t slen = tobj.str.length;
        size_t tlen = test.length;
        if (slen != tlen) {
            if (slen < tlen) {
                if (tobj.less is null) {
                    tobj.less = new Level(test, aval);
                    return;
                }
                else {
                    tobj = tobj.less;
                    goto before;
                }
            }
            else {
                if (tobj.greater is null) {
                    tobj.greater = new Level(test, aval);
                    return;
                }
                else {
                    tobj = tobj.greater;
                    goto before;
                }
            }
        }
        else {
            foreach (i; 0..slen) {
                char sc = tobj.str[i];
                char tc = test[i];
                if (sc != tc) {
                    if (sc < tc) {
                        if (tobj.less is null) {
                            tobj.less = new Level(test, aval);
                            return;
                        }
                        else {
                            tobj = tobj.less;
                            goto before;
                        }
                    }
                    else {
                        if (tobj.greater is null) {
                            tobj.greater = new Level(test, aval);
                            return;
                        }
                        else {
                            tobj = tobj.greater;
                            goto before;
                        }
                    }
                }
            }
            tobj.val = aval;
        }
    } 
}