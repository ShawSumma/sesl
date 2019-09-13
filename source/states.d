import std.range;
import std.stdio;
import std.conv;
import std.container;
import value;
import parser;
import locals;
import byteconv;
import level;

class State {
    LocalLevel[] locals;
    Value[] stack;
    size_t stacksize = 0;
    size_t stacklen = 100;
	this() {
        LocalLevel local = createLocalLevel();
		local.setLocal("nil", Value());
        local.setLocal("true", Value(true));
        local.setLocal("false", Value(false));
        local.setLocal("try", &libtry);
        local.setLocal("problem", &libproblem);
		local.setLocal("while", &libwhile);
		local.setLocal("for", &libfor);
		local.setLocal("pass", &pass);
        local.setLocal("proc", &proc);
        local.setLocal("write", &libwrite);
        local.setLocal("echo", &echo);
        local.setLocal("set", &libset);
        local.setLocal("and", &liband);
        local.setLocal("or", &libor);
        local.setLocal("get", &libget);
        local.setLocal("if", &iflib);
        local.setLocal("list", &liblist);
        local.setLocal("push", &libpush);
        local.setLocal("table", &libtable);
        local.setLocal("<", &order!"<");
        local.setLocal(">", &order!">");
        local.setLocal("<=", &order!"<=");
        local.setLocal(">=", &order!">=");
        local.setLocal("+", &libadd);
        local.setLocal("*", &libmul);
        local.setLocal("-", &libsub);
        local.setLocal("/", &libdiv);
        locals ~= local;
        stack.length = stacklen;
    }
	void set(Value name, Value v) {
		locals[$-1][to!string(name)] = v;
	} 
	void set(string name, Value v) {
		locals[$-1][name] = v;
	} 
    Value lookup(string s) {
        Value *v = s in locals[0];
        if (v) {
            return *v;
        }
        foreach_reverse (i; locals[0..$]) {
            v = s in i;
            if (v) {
                return *v;
            }
        }
        throw new Error("name not found " ~ s);
    }
	Value run(Program prog) {
        if (prog.where && prog.comp !is null) {
            size_t pl = prog.where;
            while (pl < prog.comp.opcodes.length) {
                if (stacksize + 4 > stacklen) {
                    stacklen *= 2;
                    stack.length = stacklen;
                }
                immutable Opcode op = prog.comp.opcodes[pl];
                immutable size_t arg = op.value;
                final switch (op.type) {
                    case Opcode.Type.PASS: {
                        break;
                    }
                    case Opcode.Type.FUNC: {
                        stack[stacksize] = Value(new Program(prog, pl+1));
                        stacksize ++;
                        pl = arg;
                        break;
                    }
                    case Opcode.Type.PUSH: {
                        stack[stacksize] = prog.comp.values[arg];
                        stacksize ++;
                        break;
                    }
                    case Opcode.Type.LOAD: {
                        stack[stacksize] = lookup(prog.comp.strings[arg]);
                        stacksize ++;
                        break;
                    }
                    case Opcode.Type.POP: {
                        stacksize --;
                        break;
                    }
                    case Opcode.Type.STORE: {
                        set(prog.comp.strings[arg], stack[stacksize-1]);
                        stacksize --;
                        break;
                    }
                    case Opcode.Type.CALL: {
                        stack[stacksize-1-arg] = stack[stacksize-1-arg](this, stack[stacksize-arg..stacksize]);
                        stacksize -= arg;
                        break;
                    }
                    case Opcode.Type.RET: {
                        return stack[--stacksize];
                    }
                }
                pl ++;
            }
            return stack[--stacksize];
        }
        else {
            Value ret = Value();
            foreach (i; prog.commands) {
                ret = run(i);
            }
            return ret;
        }
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
                return Value(word.value.num);
            }
            case Word.Type.PROG: {
                return Value(word.value.prog);
            }
            case Word.Type.STR: {
                return Value(word.value.str);
            }
        }
    }
}
