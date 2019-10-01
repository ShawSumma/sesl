import std.range;
import std.stdio;
import std.conv;
import std.container;
import std.algorithm;
import std.process;
import std.string;
import core.memory;
import core.stdc.stdlib;
import value;
import parser;
import level;
import errors;
import norm;

class State {
    State above = null;
    LocalLevel global = null;
    LocalLevel locals = null;
    this(State s) {
        above = s;
        global = s.global;
    }
	this(string libname) {
        global = getStdLib(libname);
    }
	void set(Value name, Value v) {
		locals[to!string(name).toLower] = v;
	} 
	void set(string name, Value v) {
		locals[name.toLower] = v;
	} 
    Value lookup(string s) {
        Value *v = s in locals;
        if (v) {
            return *v;
        }
        v = s in global;
        if (v) {
            return *v;
        }
        if (above) {
            return above.lookup(s);
        }
        throw new Problem("lookup failed for " ~ s);
    }
	Value run(Program prog) {
        Value ret = newValue();
        foreach (i; prog.commands) {
            ret = run(i.words);
        }
        return ret;
	}
	Value run(Command cmd) {
		return run(cmd.words);
	}
	Value run(Word[] words) {
        Value func;
        if (words[0].type == Word.Type.STR) {
            func = lookup(words[0].value.str);
        }
        else {
            func = run(words[0]);
        }
		Value[] args;
		size_t count = words.length - 1;
		args.length = count;
		foreach (i; 0..count) {
			args[i] = run(words[i+1]);
		}
        return func(this, args);
	}
    Value run(Word word) {
        final switch (word.type) {
            case Word.Type.LOAD: {
                return lookup(word.value.load);
            }
            case Word.Type.CMD: {
                return run(word.value.cmd);
            }
            case Word.Type.NUM: {
                return newValue(word.value.num);
            }
            case Word.Type.PROG: {
                return newValue(word.value.prog);
            }
            case Word.Type.STR: {
                return newValue(word.value.str);
            }
        }
    }
}
