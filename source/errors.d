import std.stdio;
import std.conv;
import value;

void typeMustBe(Value value, Value.Enum type) {
    if (value.type != type) {
        throw new TypeProblem("value " ~ to!string(value) ~ " is not of type " ~ to!string(type));
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
        super("bad args " ~ to!string(msg), file, line);
    }
}