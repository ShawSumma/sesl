import std.stdio;
import std.conv;
import value;

void SeslThrow(Problem prob) {
    throw prob;
}

void SeslThrow(Error prob) {
    throw prob;
}

void typeMustBe(Value value, Type type, string file=__FILE__, int line=__LINE__) {
    if ((value.type == Type.STRING || value.type == Type.BOOL) && type == Type.DOUBLE) {
        return;
    }
    if (value.type != type) {
        SeslThrow(new TypeProblem("value " ~ to!string(value) ~ " is not of type " ~ to!string(type), file, line));
    }
}

void typeMustBeIn(Value value, Type[] types, string file=__FILE__, int line=__LINE__) {
    bool okay = false;
    foreach (type; types) {
        if ((value.type == Type.STRING || value.type == Type.BOOL) && type == Type.DOUBLE) {
            okay = true;
        }
    }
    if (!okay) {
        SeslThrow(new TypeProblem("value " ~ to!string(value) ~ " is not of correct type"));
    }
}

void mustBeCallable(Value value, string file=__FILE__, int line=__LINE__) {
    if (!isCallable(value)) {
        SeslThrow(new TypeProblem("value " ~ to!string(value) ~ " is not callable", file, line));
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
    this(Value[] args,  string file=__FILE__, int line=__LINE__) {
        super("bad args " ~ to!string(args), file, line);
    }
}
