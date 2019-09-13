import std.stdio;
import std.ascii;
import std.algorithm;
import std.conv;
import std.file;
import value;
import states;
import byteconv;

class ParseString {
	string str = null;
	size_t line = 1;
	size_t col = 1;
	size_t where = 0;
	this() {}
	this(string s) {
		str = s;
	}
	char peek() {
		if (where < str.length) {
			return str[where];
		}
		return '\0';
	}
	char read() {
		char got = peek;
		where ++;
		if (got == '\n' || got == '\r') {
			line ++;
			col = 0;
		}
		col ++;
		return got;
	}
	void lstrip() {
		while (canFind("\t ", peek)) {
			read;
		}
	}
	void strip() {
		while (canFind("\r\n\t ", peek)) {
			read;
		}
	}
}

class Word {
	size_t line;
	size_t col;
	enum Type {
		LOAD,
		NUM,
		STR,
		PROG,
		CMD,
	}
	union Value {
		string str;
		string load;
		double num;
		Program prog;
		Command cmd;
	}
	Type type;
	Value value;
	this(ParseString str) {
		type = Type.NUM;
		if (str.peek == '$') {
			str.read;
			type = Type.LOAD;
		}
		if (str.peek == '{') {
			str.read;
			type = Type.PROG;
			value.prog = new Program(str);
			return;
		}
		if (str.peek == '(') {
			str.read;
			type = Type.CMD;
			value.cmd = new Command(str, false);
			return;
		}
		char[] val;
		if (str.peek == '"') {
			str.read;
			while (str.peek != '"') {
				val ~= str.read;
			}
			str.read;
			type = Type.STR;
		}
		while (!canFind("\t\r\n \0)({}$;", str.peek)) {
			char got = str.read;
			if (type == Type.NUM && !got.isDigit && got != '.') {
				type = Type.STR;
			}
			val ~= got;
		}
		final switch (type) {
			case Type.NUM: {
				value.num = parse!double(val);
				break;
			}
			case Type.LOAD: {
				value.load = cast(string) val;
				break;
			}
			case Type.STR: {
				value.str = cast(string) val;
				break;
			}
			case Type.CMD: {
				break;
			}
			case Type.PROG: {
				break;
			}
		}
	}
}

class Command {
	size_t line;
	size_t col;
	Word[] words;
	this(ParseString str, bool endline=true) {
		if (!endline) {
			str.strip;
		}
		else {
			str.lstrip;
		}
		while (!canFind("\0});", str.peek)) {
			if (endline && canFind("\r\n", str.peek)) {
				break;
			}
			words ~= new Word(str);
			if (!endline) {
				str.strip;
			}
			else {
				str.lstrip;
			}
		}
		if (str.peek == ')' || str.peek == ';') {
			str.read;
		}
	}
}

class Program {
	size_t line;
	size_t col;
	Command[] commands;
	string[] argnames;
	size_t where;
	string name;
	BytecodeCompiler comp;
	this(ParseString str) {
		str.strip;
		while (!canFind("}\0", str.peek)) {
			commands ~= new Command(str);
			str.strip;
		}
		if (str.peek == '}') {
			str.read;
		}
		where = 0;
	}
	this(Program p, size_t w) {
		where = w;
		comp = p.comp;
	}
	this(BytecodeCompiler c, size_t w=1) {
		where = w;
		comp = c;
	}
	this(Program old) {
		line = old.line;
		col = old.col;
		commands = old.commands;
		argnames = old.argnames;
		where = old.where;
		comp = old.comp;
		name = old.name;
	}
	this(Program old, string n) {
		line = old.line;
		col = old.col;
		commands = old.commands;
		argnames = old.argnames;
		where = old.where;
		comp = old.comp;
		name = n;
	}
}