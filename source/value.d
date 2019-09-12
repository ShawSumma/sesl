import std.stdio;
import std.math;
import std.algorithm;
import std.range;
import std.conv;
import states;
import parser;
import level;
import errors;

alias Fun = Value function(State state, Value[] args);

struct Value {
	enum Enum {
		NULL,
		BOOL,
		STRING,
		DOUBLE,
		LIST,
		TABLE,
		PROGRAM,
		FUNCTION,
		PROBLEM,
	}
	union Union {
		bool _bool;
		string _string;
		double _double;
		Value[] _list;
		Value[Value] _table;
		Program _program;
		Fun _function;
		Problem _problem;
	}
	Union obj;
	Enum type = Enum.NULL;
	this(bool v) {
		obj._bool = v;
		type = Enum.BOOL;
	}
	this(string v) {
		obj._string = v;
		type = Enum.STRING;
	}
	this(double v) {
		obj._double = v;
		type = Enum.DOUBLE;
	}
	this(Value[] v) {
		obj._list = v;
		type = Enum.LIST;
	}
	this(Value[Value] v) {
		obj._table = v;
		type = Enum.TABLE;
	}
	this(Program v) {
		obj._program = v;
		type = Enum.PROGRAM;
	}
	this(Fun v) {
		obj._function = v;
		type = Enum.FUNCTION;
	}
	this(Problem v) {
		obj._problem = v;
		type = Enum.PROBLEM;
	}
	size_t toHash() const nothrow {
		switch (type) {
			case Enum.DOUBLE: {
				union Union {
					double d;
					size_t s;
				}
				Union un;
				un.d = obj._double;
				return un.s;
			}
			case Enum.BOOL: {
				return obj._bool ? 2 : 1;
			}
			case Enum.NULL: {
				return 0;
			}
			case Enum.STRING: {
				return hashOf(obj._string);
			}
			default: {
				throw new Error("attempt to hash " ~ to!string(this));
			}
		}
	}
	bool opEquals(Value other) const {
		if (other.type != type) {
			return false;
		}
		switch (type) {
			case Enum.DOUBLE: {
				return obj._double == other.obj._double;
			}
			case Enum.BOOL: {
				return obj._bool == other.obj._bool;
			}
			case Enum.NULL: {
				return 0;
			}
			case Enum.STRING: {
				return obj._string == other.obj._string;
			}
			default: {
				throw new Error("attempt to compare " ~ to!string(this) ~ " and " ~ to!string(other));
			}
		}
	}
	Value opCall() {
		return this;
	}
	Value opCall(bool T=true)(State state) {
		return this.opCall!T(state, cast(Value[]) []);
	}
	Value opCall(bool T=true)(State state, Value[] args) {
		switch (type) {
			case Enum.PROGRAM: {
				LocalLevel local = createLocalLevel();
				Program prog = obj._program;
				foreach (i; 0..min(args.length, prog.argnames.length)) {
					local[prog.argnames[i]] = args[i];
				}
				static if (T) {
					state.locals ~= local;
				}
				Value ret = state.run(prog);
				static if (T) {
					state.locals.popBack;
				}
				return ret;
			}
			case Enum.FUNCTION: {
				return obj._function(state, args);
			}
			case Enum.TABLE: {
				goto case;
			}
			case Enum.LIST: {
				Value got = this;
				foreach (i; args) {
					if (got.type == Enum.LIST) {
						got = got.obj._list[cast(size_t) i.obj._double];
					}
					else if (got.type == Enum.TABLE) {
						got = got.obj._table[i];
					}
					else {
						throw new Error("cannot index " ~ to!string(got));
					}
				}
				return got;
			}
			default: {
				throw new Error("not callable " ~ to!string(this));
			}
		}
	}
	string toString() {
		final switch (type) {
			case Enum.NULL: {
				return "null";
			}
			case Enum.BOOL: {
				return to!string(obj._bool);
			}
			case Enum.STRING: {
				return to!string(obj._string);
			}
			case Enum.DOUBLE: {
				return to!string(obj._double);
			}
			case Enum.LIST: {
				return "<list>";
			}
			case Enum.TABLE: {
				return "<table>";
			}
			case Enum.PROGRAM: {
				return "<program>";
			}
			case Enum.FUNCTION: {
				return "<function>";
			}
			case Enum.PROBLEM: {
				return to!string(obj._problem.msg);
			}
		}
	}
	bool boolean() {
		if (type == Enum.NULL) {
			return false;
		}
		if (type == Enum.BOOL) {
			return obj._bool;
		}
		return true;
	}
}
