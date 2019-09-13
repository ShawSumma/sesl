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
alias Type = Value.Enum;

struct ValueFun {
	Fun fun;
	string name;
	this(Fun f, string n) {
		fun = f;
		name = n;
	}
}

string printer(Value cur, Value[] above=null) {
	foreach (i; above) {
		if (cur == i) {
			return "...";
		}
	}
	final switch (cur.type) {
		case Type.NULL: {
			return "null";
		}
		case Type.BOOL: {
			return to!string(cur.obj._bool);
		}
		case Type.STRING: {
			return to!string(cur.obj._string);
		}
		case Type.DOUBLE: {
			return to!string(cur.obj._double);
		}
		case Type.LIST: {
			string lis;
			above ~= cur;
			foreach (i; cur.obj._list) {
				lis ~= " ";
				lis ~= printer(i, above);
			}
			above.popBack;
			return "(list" ~ lis ~ ")";
		}
		case Type.TABLE: {
			above ~= cur;
			string lis;
			foreach (i; cur.obj._table.byKeyValue) {
				lis ~= " ";
				lis ~= printer(i.key, above);
				lis ~= " ";
				lis ~= printer(i.value, above);
			}
			above.popBack;
			return "(table" ~ lis ~ ")";
		}
		case Type.PROGRAM: {
			return "<program>";
		}
		case Type.FUNCTION: {
			return "<function>";
		}
		case Type.PROBLEM: {
			return to!string(cur.obj._problem.msg);
		}
	}
}

class Value {
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
		ValueFun _function;
		Problem _problem;
	}
	Union obj;
	Enum type = Enum.NULL;
	this() {
		type = Enum.NULL;
	}
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
	this(Fun v, string name) {
		obj._function = ValueFun(v, name);
		type = Enum.FUNCTION;
	}
	this(Problem v) {
		obj._problem = v;
		type = Enum.PROBLEM;
	}
	override size_t toHash() const nothrow {
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
		final switch (type) {
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
			case Enum.FUNCTION: {
				return false;
			}
			case Enum.PROGRAM: {
				return false;
			}
			case Enum.PROBLEM: {
				return false;
			}
			case Enum.LIST: {
				if (obj._list.length != other.obj._list.length) {
					return false;
				}
				foreach (i; 0..obj._list.length) {
					if (obj._list[i] != other.obj._list[i]) {
						return false;
					}
				}
				return true;
			}
			case Enum.TABLE: {
				if (obj._table.length != other.obj._table.length) {
					return false;
				}
				foreach (i; obj._table.byKeyValue) {
					Value *v = i.key in other.obj._table;
					if (v == null) {
						return false;
					}
					if (*v != i.value) {
						return false;
					}
				}
				return true;
			}
		}
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
				return obj._function.fun(state, args);
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
						throw new Problem("cannot index " ~ to!string(got));
					}
				}
				return got;
			}
			default: {
				throw new Problem("not callable " ~ to!string(this));
			}
		}
	}
	override string toString() {
		return printer(this);
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
