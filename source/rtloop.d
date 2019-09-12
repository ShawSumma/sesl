import std.algorithm;
import std.stdio;
import std.conv;
import parser;
import states;
import byteconv;
import value;

void repl() {
    State state = new State();
    while (true) {
        string code;
        ulong diff = 0;
        write(">>> ");
        do {
            foreach (i; 0..diff) {
                write("    ");
            }
            code ~= readln;
            diff = code.count('{') != code.count('}');
            if (diff != 0) {
                write("    ");
            }
        } while (diff != 0);
        ParseString str = new ParseString(code);
        Program prog = new Program(str);
        Value got = state.run(prog);
        if (got.type != Value.Enum.NULL) {
            writeln(got);
        }
    }
}