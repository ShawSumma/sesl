import std.stdio;
import std.math;
import std.algorithm;
import std.functional;
import std.range;
import std.conv;
import core.memory;
import states;
import parser;
import level;
import errors;

Value newValue(T...)(T args) {
	return Value(args);
}

alias Fun = Value delegate(State, Value[]);
alias Type = Value.Enum;

struct ValueFun {
	Fun fun;
	string name;
	this(Fun f, string n) {
		fun = f;
		name = n;
	}
	this(Value function(State, Value[]) f, string n) {
		fun = toDelegate(f);
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
			return "nil";
		}
		case Type.BOOL: {
			return to!string(cur.obj._bool);
		}
		case Type.STRING: {
			if (above.length == 0) {
				return to!string(cur.obj._string);
			}
			else {
				return "\"" ~ to!string(cur.obj._string) ~ "\"";
			}
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
			if (cur.obj._program.name.length != 0) {
				return "<program " ~ cur.obj._program.name ~ ">";
			}
			else {
				return "<program>";
			}
		}
		case Type.FUNCTION: {
			return "<function " ~ cur.obj._function.name ~ ">";
		}
		case Type.PROBLEM: {
			return to!string(cur.obj._problem.msg);
		}
	}
}

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
		ValueFun _function;
		Problem _problem;
	}
	Union obj;
	Enum type = Enum.NULL;
	// this() {}
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
	this(ValueFun v) {
		obj._function = v;
		type = Enum.FUNCTION;
	}
	this(Problem v) {
		obj._problem = v;
		type = Enum.PROBLEM;
	}
	double _double() {
		switch (type) {
			case Enum.DOUBLE: {
				return obj._double;
			}
			case Enum.STRING: {
				obj._double = parse!double(obj._string);
				type = Enum.DOUBLE;
				break;
			}
			case Enum.BOOL: {
				obj._double = obj._bool ? 0 : 1;
				type = Enum.DOUBLE;
				break;
			}
			default: {
				throw new Problem("Cannot convert " ~ to!string(this) ~ " to number");
			}
		}
		return obj._double;
	}
	//override
	size_t toHash() const nothrow
	// @trusted
	{
		switch (type) {
			case Enum.DOUBLE: {
				return hashOf(obj._double);
			}
			case Enum.NULL: {
				return 0;
			}
			case Enum.BOOL: {
				return obj._bool + 1;
			}
			case Enum.STRING: {
				return hashOf(obj._string);
			}
			default: {
				return -1;
			}
		}
	}
	bool opEquals(Value oobj) const {
		Value other = cast(Value) oobj;
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
				return true;
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
		return this.opCall!T(state, cast(Value[]) null);
	}
	Value opCall(bool T=true)(State state, Value[] args) {
		switch (type) {
			case Enum.STRING: {
				return state.lookup(obj._string).opCall!T(state, args);
			}
			case Enum.DOUBLE: {
				return state.lookup(to!string(obj._double)).opCall!T(state, args);
			}
			case Enum.PROGRAM: {
				LocalLevel local = createLocalLevel();
				Program prog = obj._program;
				ulong nargc = min(args.length, prog.argnames.length);
				foreach (i; 0..nargc) {
					local[prog.argnames[i]] = args[i];
				}
				local["args"] = newValue(args);
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
	// override
	string toString() {
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

bool isCallable(Value value) {
	return value.type == Type.FUNCTION || value.type == Type.PROGRAM
        || value.type == Type.STRING || value.type == Type.DOUBLE
        || value.type == Type.LIST || value.type == Type.TABLE;
}

bool isFunction(Value value) {
	return value.type == Type.FUNCTION || value.type == Type.PROGRAM;
}