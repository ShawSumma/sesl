import std.stdio;
import value;
import locals;
import states;

version = LOCALS_ARE_AA;

version (LOCALS_ARE_AA) {
    alias LocalLevel = Value[string];
}
version (LOCALS_ARE_LEVEL) {
    alias LocalLevel = Level;
}

LocalLevel createLocalLevel() {
    version (LOCALS_ARE_AA) {
        return null;
    }
    version (LOCALS_ARE_LEVEL) {
        return LocalLevel();
    }
}

void setLocal(ref LocalLevel lvl, string name, Value val) {
    lvl[name] = val;
}

void setLocal(ref LocalLevel lvl, string name, Value function(State, Value[]) val) {
    lvl[name] = newValue(ValueFun(val, name));
}

void setLocal(ref LocalLevel lvl, string name, Fun val) {
    lvl[name] = newValue(ValueFun(val, name));
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