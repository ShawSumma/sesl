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
            diff = notOkay(code);
            if (diff) {
                write("    ");
            }
        } while (diff);
        ParseString str = new ParseString(code);
        Program prog = new Program(str);
        Value got = state.run(prog);
        if (got.type != Type.NULL) {
            writeln(got);
        }
    }
}