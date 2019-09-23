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
import locals;
import byteconv;
import level;
import errors;

version = ONE_STACK;

class State {
    LocalLevel[] locals;
    version (ONE_STACK) {
        size_t stacksize = 0;
        size_t stackalloc = 4;
        Value* stack;
    }
	this() {
        LocalLevel local = createLocalLevel();
        // string[string] environ = environment.toAA;
        // foreach (kv; environ.byKeyValue) {
        //     local.setLocal(kv.key.toLower, newValue(kv.value));
        // }
		local.setLocal("nil", newValue());

        local.setLocal("try", &libtry);
        local.setLocal("problem", &libproblem);

		local.setLocal("while", &libwhile);
		local.setLocal("for", &libfor);
		local.setLocal("foreach", &libforeach);

		local.setLocal("pass", &pass);
        local.setLocal("proc", &proc);

        local.setLocal("write", &libwrite);
        local.setLocal("echo", &echo);
        
        local.setLocal("true", newValue(true));
        local.setLocal("false", newValue(false));
        local.setLocal("and", &liband);
        local.setLocal("or", &libor);
        local.setLocal("if", &iflib);

        local.setLocal("set", &libset);
        local.setLocal("get", &libget);

        local.setLocal("list", &liblist);
        local.setLocal("push", &libpush);
        local.setLocal("table", &libtable);

        local.setLocal("<", &order!"<");
        local.setLocal(">", &order!">");
        local.setLocal("<=", &order!"<=");
        local.setLocal(">=", &order!">=");
        local.setLocal("=", &libequal);
        local.setLocal("!=", &libnotequal);
        
        local.setLocal("+", &libadd);
        local.setLocal("*", &libmul);
        local.setLocal("-", &libsub);
        local.setLocal("/", &libdiv);
        local.setLocal("%", &libmod);

        local.setLocal("vars", &libvars);
        local.setLocal("names", &libnames);

        local.setLocal("each", &libeach);
        local.setLocal("apply", &libapply);
        local.setLocal("inject", &libinject);
        local.setLocal("filter", &libfilter);
        local.setLocal("range", &librange);
        local.setLocal("into", &libinto);

        locals ~= local;
        version (ONE_STACK) {
           stack = cast(Value *) GC.malloc(Value.sizeof * stackalloc);
        }
    }
	void set(Value name, Value v) {
		locals[$-1][to!string(name).toLower] = v;
	} 
	void set(string name, Value v) {
		locals[$-1][name.toLower] = v;
	} 
    Value lookup(string s) {
        s = s.toLower;
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
            version (MANY_STACK) {
                size_t stacksize = 0;
                Value* stack = cast(Value *) GC.malloc(Value.sizeof * prog.stackneed);
            }
            version (ONE_STACK) {
                void check() {
                    if (stacksize + 1 >= stackalloc) {
                        stackalloc *= 2;
                        stack = cast(Value *) GC.realloc(stack, Value.sizeof * stackalloc);
                    } 
                }
            }
            size_t pl = prog.where;
            while (pl < prog.comp.opcodes.length) {
                immutable Opcode op = prog.comp.opcodes[pl];
                immutable size_t arg = op.value;
                final switch (op.type) {
                    case Opcode.Type.PASS: {
                        break;
                    }
                    case Opcode.Type.FUNC: {
                        version (ONE_STACK) { check; }
                        Program p = new Program(prog, pl+1, prog.comp.ulongs[arg+1]);
                        stack[stacksize] = newValue(p);
                        pl = prog.comp.ulongs[arg];
                        stacksize ++;
                        break;
                    }
                    case Opcode.Type.PUSH: {
                        version (ONE_STACK) { check; }
                        stack[stacksize] = prog.comp.values[arg];
                        stacksize ++;
                        break;
                    }
                    case Opcode.Type.LOAD: {
                        version (ONE_STACK) { check; }
                        stack[stacksize] = lookup(prog.comp.strings[arg]);
                        stacksize ++;
                        break;
                    }
                    case Opcode.Type.POP: {
                        stacksize --;
                        break;
                    }
                    case Opcode.Type.CALL: {
                        stacksize -= arg;
                        version (MANY_STACK) {
                            stack[stacksize-1] = stack[stacksize-1](
                                this,
                                stack[stacksize..stacksize+arg]
                            );
                        }
                        version (ONE_STACK) {
                            Value v = stack[stacksize-1](
                                this,
                                stack[stacksize..stacksize+arg].dup
                            );
                            stack[stacksize-1] = v;
                        }
                        break;
                    }
                    case Opcode.Type.RET: {
                        // GC.free(stack);
                        return stack[--stacksize];
                    }
                }
                pl ++;
            }
            // GC.free(stack);
            return stack[--stacksize];
        }
        else {
            Value ret = newValue();
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
