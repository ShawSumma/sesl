import std.stdio;
import std.conv;
import value;

void typeMustBe(Value value, Type type, string file=__FILE__, int line=__LINE__) {
    if (value.type != type) {
        throw new TypeProblem("value " ~ to!string(value) ~ " is not of type " ~ to!string(type), file, line);
    }
}

void mustBeCallable(Value value, string file=__FILE__, int line=__LINE__) {
    if (value.type != Type.FUNCTION && value.type != Type.PROGRAM) {
        throw new TypeProblem("value " ~ to!string(value) ~ " is not callable", file, line);
    }
}

class Problem: Exception {
    this(string msg, string file=__FILE__, int line=__LINE__) {
        super(msg, file, line);
    }
}

class TypeProblem: Problem {
    this(string msg, string file=__FILE__, int line=__LINE__) {
        super(msg, file, line);
    }
}

class ArgcProblem: Problem {
    this(string msg, string file=__FILE__, int line=__LINE__) {
        super(msg, file, line);
    }
    this(Args args,  string file=__FILE__, int line=__LINE__) {
        super("bad args " ~ to!string(args.copy), file, line);
    }
}