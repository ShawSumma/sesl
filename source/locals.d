import std.stdio;
import std.range;
import std.conv;
import parser;
import states;
import errors;
import level;
import value;

Value echo(State state, Value[] args) {
    foreach (i; 0..args.length) {
        if (i != 0) {
            write(" ");
        }
        write(args[i]);
    }
    writeln;
    return Value();
}

Value libset(State state, Value[] args) {
    state.set(args[0], args[1]);
    return args[1];
}

Value libget(State state, Value[] args) {
    return state.lookup(args[0].obj._string);
}

Value libadd(State state, Value[] args) {
    double n = 0;
    foreach (i; args) {
        n += i.obj._double;
    }
    return Value(n);
}

Value libsub(State state, Value[] args) {
    if (args.length == 1) {
        return Value(-args[0].obj._double);
    }
    double n = args[0].obj._double;
    foreach (i; args[1..$]) {
        n -= i.obj._double;
    }
    return Value(n);
}

Value libmul(State state, Value[] args) {
    double n = 1;
    foreach (i; args) {
        n *= i.obj._double;
    }
    return Value(n);
}

Value libdiv(State state, Value[] args) {
    if (args.length == 1) {
        return Value(1/args[0].obj._double);
    }
    double n = args[0].obj._double;
    foreach (i; args[1..$]) {
        n /= i.obj._double;
    }
    return Value(n);
}

Value libmod(State state, Value[] args) {
    double n = args[0].obj._double;
    foreach (i; args[1..$]) {
        n = n % i.obj._double;
    }
    return Value(n);
}

Value order(string S)(State state, Value[] args) {
    Value v = args[0];
    foreach (i; args[1..$]) {
        if (mixin("v.obj._double" ~ S ~ "i.obj._double")) {
            v = i;
        }
        else {
            return Value(false);
        }
    }
    return Value(true);
}

Value proc(State state, Value[] args) {
    Program fnpre = args[$-1].obj._program;
    Program fn = new Program(fnpre);
    foreach (i; args[1..$-1]) {
        fn.argnames ~= i.obj._string;
    }
    state.set(args[0], Value(fn));
    return Value();
}

Value iflib(State state, Value[] args) {
    Value ret;
    if (args[0].boolean) {
        ret = args[1].opCall!false(state);
    }
    else if (args.length == 3) {
        ret = args[2].opCall!false(state);
    }
    else {
        ret = Value();
    }
    return ret;
}

Value pass(State state, Value[] args) {
    return args[$-1];
}

Value liblist(State state, Value[] args) {
    return Value(args);
}

Value libtable(State state, Value[] args) {
    Value[Value] table;
    bool store = false;
    Value hold = Value();
    foreach (i; args) {
        if (store) {
            table[hold] = i;
        }
        else {
            hold = i;
        }
        store = !store;
    }
    return Value(table);
}

Value libwhile(State state, Value[] args) {
    Value ret = Value();
    while (args[0].opCall!false(state).boolean) {
        ret = args[1].opCall!false(state);
    }
    return ret;
}

Value libfor(State state, Value[] args) {
    Value ret = Value();
    args[0].opCall!false(state);
    while (args[1].opCall!false(state).boolean) {
        ret = args[3].opCall!false(state);
        args[2].opCall!false(state);
    }
    return ret;
}

Value libwrite(State state, Value[] args) {
    foreach (i; 0..args.length) {
        if (i != 0) {
            write(" ");
        }
        write(args[i]);
    }
    return Value();
}

Value liband(State state, Value[] args) {
    foreach (fn; args) {
        Value v = fn.opCall!false(state);
        if (!v.boolean) {
            return v;
        }
    }
    return Value(true);
}

Value libor(State state, Value[] args) {
    foreach (fn; args) {
        Value v = fn.opCall!false(state);
        if (v.boolean) {
            return v;
        }
    }
    return Value(false);
}

Value libproblem(State state, Value[] args) {
    if (args.length == 1 && args[0].type == Value.Enum.PROBLEM) {
        throw args[0].obj._problem;
    }
    else {
        string problem;
        foreach (i; 0..args.length) {
            if (i != 0) {
                problem ~= " ";
            }
            problem ~= to!string(args[i]);
        }
        throw new Problem(problem);
    }
}

Value libtry(State state, Value[] args) {
    switch (args.length) {
        case 1: {
            try {
                return args[0](state);
            }
            catch (Problem prob) {
                return Value();
            }
        }
        case 2: {
            try {
                return args[0](state);
            }
            catch (Problem prob) {
                return args[1](state);
            }
        }
        case 3: {
            try {
                return args[0](state);
            }
            catch (Problem problem) {
                LocalLevel local = createLocalLevel();
                local[to!string(args[1])] = Value(problem);
                state.locals ~= local;
                Value ret = args[2].opCall!false(state);
                state.locals.popBack;
                return ret;
            }
        }
        default: {
            throw new ArgcProblem(args);
        }
    }
}