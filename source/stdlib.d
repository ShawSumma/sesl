import std.stdio;
import std.range;
import std.conv;
import std.algorithm;
import core.memory;
import parser;
import states;
import errors;
import level;
import value;
import ast;

Value echo(State state, Value[] args) {
    foreach (i; 0..args.length) {
        if (i != 0) {
            write(" ");
        }
        write(args[i]);
    }
    writeln;
    return newValue();
}

Value libset(State state, Value[] args) {
    if (args.length == 2) {
        state.set(args[0], args[1]);
        return args[1];
    }
    else {
        Value ret = state.lookup(state.get!string(args[0]));
        Value v = ret;
        foreach (i; args[1..$-2]) {
            v = v.opCall(state, [i]);
        }
        if (v.type == Type.LIST) {
            v.obj._list[cast(ulong) state.get!double(args[$-2])] = args[$-1];
        }
        else if (v.type == Type.TABLE) {
            v.obj._table[args[$-2]] = args[$-1];
        }
        else {
            throw new Problem("cannot set index of " ~ to!string(v));
        }
        return ret;
    }
}

Value libget(State state, Value[] args) {
    return state.lookup(state.get!string(args[0]));
}

Value libadd(State state, Value[] args) {
    double n = 0;
    foreach (i; args) {
        n += state.get!double(i);
    }
    return newValue(n);
}

Value libsub(State state, Value[] args) {
    if (args.length == 1) {
        return newValue(-state.get!double(args[0]));
    }
    double n = state.get!double(args[0]);
    foreach (i; args[1..$]) {
        n -= state.get!double(i);
    }
    return newValue(n);
}

Value libmul(State state, Value[] args) {
    double n = 1;
    foreach (i; args) {
        n *= state.get!double(i);
    }
    return newValue(n);
}

Value libdiv(State state, Value[] args) {
    if (args.length == 1) {
        return newValue(1/state.get!double(args[0]));
    }
    double n = state.get!double(args[0]);
    foreach (i; args[1..$]) {
        n /= state.get!double(i);
    }
    return newValue(n);
}

Value libmod(State state, Value[] args) {
    double n = state.get!double(args[0]);
    foreach (i; args[1..$]) {
        n = n % state.get!double(i);
    }
    return newValue(n);
}

Value libpow(State state, Value[] args) {
    double n = state.get!double(args[0]);
    foreach (i; args[1..$]) {
        n = n ^^ state.get!double(i);
    }
    return newValue(n);
}

Value order(string S)(State state, Value[] args) {
    Value v = args[0];
    foreach (i; args[1..$]) {
        if (!mixin("state.get!double(v)" ~ S ~ "state.get!double(i)")) {
            return newValue(false);
        }
        v = i;
    }
    return newValue(true);
}

Value libnotequals(State state, Value[] args) {
    foreach (i; 1..args.length) {
        foreach (j; 0..i) {
            if (i == j) {
                return newValue(false);
            }
        }
    }
    return newValue(true); 
}

Value libequals(State state, Value[] args) {
    foreach (i; 1..args.length) {
        foreach (j; 0..i) {
            if (i != j) {
                return newValue(false);
            }
        }
    }
    return newValue(true);
}

Value proc(State state, Value[] args) {
    Program fnpre = args[$-1].obj._program;
    Program fn = new Program(fnpre, state.get!string(args[0]));
    fn.argnames = null;
    foreach (i; args[1..$-1]) {
        fn.argnames ~= state.get!string(i);
    }
    state.set(args[0], newValue(fn));
    return newValue();
}

Value iflib(State state, Value[] args) {
    Value ret;
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

Value pass(State state, Value[] args) {
    if (args.length == 0) {
        SeslThrow(new ArgcProblem(args));
    }
    return args[$-1];
}

Value liblist(State state, Value[] args) {
    return newValue(args);
}

Value libtable(State state, Value[] args) {
    if (args.length % 2 != 0) {
        SeslThrow(new ArgcProblem(args));
    }
    Value[Value] table;
    foreach (i; 0..args.length) {
        if (i % 2 == 0) {
            table[args[i]] = args[i+1];
        }
    }
    return newValue(table);
}

Value libwhile(State state, Value[] args) {
    Value ret = newValue();
    while (args[0].opCall!false(state).boolean) {
        ret = args[1].opCall!false(state);
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
    stdout.flush;
    return newValue();
}

Value libpush(State state, Value[] args) {
    args[0].obj._list ~= args[1..$];
    return args[0];
} 

Value libpop(State state, Value[] args) {
    args[0].obj._list.popBack;
    return args[0];
}

Value liband(State state, Value[] args) {
    foreach (i; args) {
        mustBeCallable(i);
    }
    foreach (fn; args) {
        Value v = fn.opCall!false(state);
        if (!v.boolean) {
            return v;
        }
    }
    return newValue(true);
}

Value libor(State state, Value[] args) {
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

Value libproblem(State state, Value[] args) {
    if (args.length == 1 && args[0].type == Type.PROBLEM) {
        SeslThrow(state.get!Problem(args[0]));
    }
    else {
        string problem;
        foreach (i; 0..args.length) {
            if (i != 0) {
                problem ~= " ";
            }
            problem ~= state.get!string(args[i]);
        }
        SeslThrow(new Problem(problem));
    }
    assert(0);
}

Value libtry(State state, Value[] args) {
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
                return args[2].opCall!false(state, [newValue(problem)]);
            }
        }
        default: {
            SeslThrow(new ArgcProblem(args));
        }
    }
    assert(0);
}

Value libequal(State state, Value[] args) {
    foreach (i, v1; args) {
        foreach (j, v2; args) {
            if (i != j && v1 != v2) {
                return newValue(false);
            }
        }
    }
    return newValue(true);
}

Value libnotequal(State state, Value[] args) {
    foreach (i, v1; args) {
        foreach (j, v2; args) {
            if (i != j && v1 == v2) {
                return newValue(false);
            }
        }
    }
    return newValue(true);
}

Value libforeach(State state, Value[] args) {
    Value[] ret;
    Value fn = args[1];
    mustBeCallable(fn);
    foreach (i; state.get!(Value[])(args[0])) {
        ret ~= fn(state, [i]);
    }
    return newValue(ret);
}

Value libapply(State state, Value[] args) {
    mustBeCallable(args[$-1]);
    if (args.length == 2) {
        return args[$-1](
            state,
            args[$-2].obj._list
        );
    }
    else {
        return args[$-1](
            state,
            args[0..$-2] ~ args[$-2].obj._list
        );
    }
    
}
Value libfold(State state, Value[] args) {
    Value fn = args[$-1];
    mustBeCallable(fn);
    if (args.length == 3) {
        Value value = args[1];
        foreach (i; args[0].obj._list) {
            value = fn(state, [value, i]);
        }
        return value;
    }
    else {
        Value value = args[0].obj._list[0];
        foreach (i; args[0].obj._list[1..$]) {
            value = fn(state, [value, i]);
        }
        return value;
    }
}

Value libfilter(State state, Value[] args) {
    Value[] ret;
    Value fn = args[1];
    mustBeCallable(fn);
    foreach (i; args[0].obj._list) {
        if (fn(state, [i]).boolean) {
            ret ~= i;
        }
    }
    return newValue(ret);
}

Value librange(State state, Value[] args) {
    Value[] ret;
    if (args.length == 1) {
        foreach (i; 0..state.get!double(args[0])) {
            ret ~= newValue(i);
        }
    }
    else {
        foreach (i; state.get!double(args[0])..state.get!double(args[1])) {
            ret ~= newValue(i);
        }
    }
    return newValue(ret);
}

Value libinto(State state, Value[] args) {
    state.set(args[1], args[0]);
    return args[0];
}

Value libfor(State state, Value[] args) {
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

Value libnot(State state, Value[] args) {
    return newValue(!args[$-1].boolean);
}

Value libstrcat(State state, Value[] args) {
    char[] ret;
    foreach (i; args) {
        ret ~= state.get!string(i);
    }
    return newValue(cast(string) ret);
}

Value liblength(State state, Value[] args) {
    return newValue(state.get!(Value[])(args[0]).length);
}

Value libcurry(State state, Value[] args) {
    mustBeCallable(args[0]);
    Value[] rest = args[1..$];
    Value func(State substate, Value[] subargs) {
        return args[0](substate, rest ~ subargs);
    }
    return newValue(ValueFun(&func, ""));
}

Value libcommands(State state, Value[] args) {
    return args[0].obj._program.astValue;
}

Value libchar(State state, Value[] args) {
    return newValue(cast(double) state.get!string(args[0])[0]);
}

Value libascii(State state, Value[] args) {
    return newValue(cast(string) [state.get!double(args[0])]);
}

Value libmemsize(State state, Value[] args) {
    return newValue(GC.stats().usedSize);
}

Value libcollect(State state, Value[] args) {
    GC.collect;
    return newValue();
}