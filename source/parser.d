import std.stdio;
import std.ascii;
import std.algorithm;
import std.conv;
import std.file;
import value;
import states;

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
	char read(bool B=true)() {
		char got = peek;
		where ++;
		if (got == '\n' || got == '\r') {
			line ++;
			col = 0;
		}
		col ++;
		static if (B) {
			if (got == '#') {
				while (peek != '\n' && peek != '\r' && peek != '\0') {
					read;
				}
				return '\n';
			}
		}
		return got;
	}
	void lstrip(bool B=true)() {
		while (canFind("\t #", peek)) {
			static if (B) {
				if (peek == '#') {
					while (peek != '\n' && peek != '\r' && peek != '\0') {
						read;
					}
					lstrip;
				}
			}
			read;
		}
	}
	void strip(bool B=true)() {
		while (canFind("\r\n\t ", peek)) {
			static if (B) {
				while (peek == '#') {
					while (peek != '\n' && peek != '\r' && peek != '\0') {
						read;
					}
					strip;
				}
			}
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
	this(Command cmd) {
		type = Type.CMD;
		value.cmd = cmd;
	}
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
				val ~= str.read!false;
			}
			str.read;
			type = Type.STR;
		}
		while (!canFind("\t\r\n \0(){}$&;|", str.peek)) {
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
	Word[] words;
	this(Word[] ws=null) {
		words = ws;
	}
	this(ParseString str, bool endline=true) {
		void dostrip() {
			if (!endline) {
				str.strip;
			}
			else {
				str.lstrip;
			}
		}
		dostrip;
		while (!canFind("\0});", str.peek)) {
			if (endline && canFind("\r\n", str.peek)) {
				break;
			}
			words ~= new Word(str);
			dostrip;
			while (str.peek == '|') {
				str.read;
				dostrip;
				Command oldthis = new Command();
				oldthis.words = words;
				Word first = new Word(str);
				words = [first, new Word(oldthis)];
				dostrip;
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
	this(Program old) {
		line = old.line;
		col = old.col;
		commands = old.commands;
		argnames = old.argnames;
		where = old.where;
		name = old.name;
	}
	this(Program old, string n) {
		line = old.line;
		col = old.col;
		commands = old.commands;
		argnames = old.argnames;
		where = old.where;
		name = n;
	}
}
