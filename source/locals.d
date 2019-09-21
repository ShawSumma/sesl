import std.stdio;
import std.range;
import std.conv;
import parser;
import states;
import errors;
import level;
import value;

Value echo(State state, Args args) {
    foreach (i; 0..args.length) {
        if (i != 0) {
            write(" ");
        }
        write(args[i]);
    }
    writeln;
    return newValue();
}

Value libset(State state, Args args) {
    state.set(args[0], args[1]);
    return args[1];
}

Value libget(State state, Args args) {
    return state.lookup(args[0].obj._string);
}

Value libadd(State state, Args args) {
    foreach (i; args) {
        typeMustBe(i, Type.DOUBLE);
    }
    double n = 0;
    foreach (i; args) {
        n += i.obj._double;
    }
    return newValue(n);
}

Value libsub(State state, Args args) {
    foreach (i; args) {
        typeMustBe(i, Type.DOUBLE);
    }
    if (args.length == 1) {
        return newValue(-args[0].obj._double);
    }
    double n = args[0].obj._double;
    foreach (i; args[1..$]) {
        n -= i.obj._double;
    }
    return newValue(n);
}

Value libmul(State state, Args args) {
    foreach (i; args) {
        typeMustBe(i, Type.DOUBLE);
    }
    double n = 1;
    foreach (i; args) {
        n *= i.obj._double;
    }
    return newValue(n);
}

Value libdiv(State state, Args args) {
    foreach (i; args) {
        typeMustBe(i, Type.DOUBLE);
    }
    if (args.length == 1) {
        return newValue(1/args[0].obj._double);
    }
    double n = args[0].obj._double;
    foreach (i; args[1..$]) {
        n /= i.obj._double;
    }
    return newValue(n);
}

Value libmod(State state, Args args) {
    foreach (i; args) {
        typeMustBe(i, Type.DOUBLE);
    }
    double n = args[0].obj._double;
    foreach (i; args[1..$]) {
        n = n % i.obj._double;
    }
    return newValue(n);
}

Value order(string S)(State state, Args args) {
    foreach (i; args) {
        typeMustBe(i, Type.DOUBLE);
    }
    Value v = args[0];
    bool result = true;
    foreach (i; args[1..$]) {
        if (!mixin("v.obj._double" ~ S ~ "i.obj._double")) {
            result = false;
            break;
        }
        v = i;
    }
    return newValue(result);
}

Value proc(State state, Args args) {
    foreach (i; args[1..$-1]) {
        typeMustBe(i, Type.STRING);
    }
    Program fnpre = args[$-1].obj._program;
    Program fn = new Program(fnpre, to!string(args[0]));
    fn.argnames = null;
    foreach (i; args[1..$-1]) {
        fn.argnames ~= i.obj._string;
    }
    state.set(args[0], newValue(fn));
    return newValue();
}

Value iflib(State state, Args args) {
    Value ret;
    mustBeCallable(args[0]);
    if (args[0].opCall!false(state).boolean) {
        mustBeCallable(args[1]);
        ret = args[1].opCall!false(state);
    }
    else if (args.length == 3) {
        mustBeCallable(args[1]);
        mustBeCallable(args[2]);
        ret = args[2].opCall!false(state);
    }
    else {
        ret = newValue();
    }
    return ret;
}

Value pass(State state, Args args) {
    if (args.length == 0) {
        throw new ArgcProblem(args);
    }
    return args[$-1];
}

Value liblist(State state, Args args) {
    return newValue(args.copy);
}

Value libtable(State state, Args args) {
    if (args.length % 2 != 0) {
        throw new ArgcProblem(args);
    }
    Value[Value] table;
    foreach (i; 0..args.length) {
        if (i % 2 == 0) {
            table[args[i]] = args[i+1];
        }
    }
    return newValue(table);
}

Value libwhile(State state, Args args) {
    Value ret = newValue();
    mustBeCallable(args[1]);
    while (args[0].opCall!false(state).boolean) {
        ret = args[1].opCall!false(state);
    }
    return ret;
}

Value libfor(State state, Args args) {
    Value ret = newValue();
    mustBeCallable(args[0]);
    mustBeCallable(args[1]);
    mustBeCallable(args[2]);
    mustBeCallable(args[3]);
    args[0].opCall!false(state);
    while (args[1].opCall!false(state).boolean) {
        ret = args[3].opCall!false(state);
        args[2].opCall!false(state);
    }
    return ret;
}

Value libwrite(State state, Args args) {
    foreach (i; 0..args.length) {
        if (i != 0) {
            write(" ");
        }
        write(args[i]);
    }
    return newValue();
}

Value libpush(State state, Args args) {
    typeMustBe(args[0], Type.LIST);
    args[0].obj._list ~= args[1..$].copy;
    return args[0];
} 

Value liband(State state, Args args) {
    foreach (i; args) {
        mustBeCallable(i);
    }
    Value ret = newValue(true);
    foreach (fn; args) {
        Value v = fn.opCall!false(state);
        if (!v.boolean) {
            return v;
        }
    }
    return newValue(true);
}

Value libor(State state, Args args) {
    foreach (i; args) {
        mustBeCallable(i);
    }
    foreach (fn; args) {
        Value v = fn.opCall!false(state);
        if (v.boolean) {
            return v;
        }
    }
    return newValue(false);
}

Value libproblem(State state, Args args) {
    if (args.length == 1 && args[0].type == Type.PROBLEM) {
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

Value libtry(State state, Args args) {
    switch (args.length) {
        case 1: {
            mustBeCallable(args[0]);
            try {
                return args[0](state);
            }
            catch (Problem prob) {
                return newValue();
            }
        }
        case 2: {
            mustBeCallable(args[0]);
            mustBeCallable(args[1]);
            try {
                return args[0](state);
            }
            catch (Problem prob) {
                return args[1](state);
            }
        }
        case 3: {
            mustBeCallable(args[0]);
            mustBeCallable(args[2]);
            try {
                return args[0](state);
            }
            catch (Problem problem) {
                LocalLevel local = createLocalLevel();
                local[to!string(args[1])] = newValue(problem);
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

Value libequal(State state, Args args) {
    foreach (i, v1; args) {
        foreach (j, v2; args) {
            if (i != j && v1 != v2) {
                return newValue(false);
            }
        }
    }
    return newValue(true);
}

Value libnotequal(State state, Args args) {
    foreach (i, v1; args) {
        foreach (j, v2; args) {
            if (i != j && v1 == v2) {
                return newValue(false);
            }
        }
    }
    return newValue(true);
}

Value libexpr(State state, Args args) {
    throw new Problem("Expr not implemented");
}