import std.algorithm;
import std.stdio;
import std.conv;
import parser;
import states;
import byteconv;
import value;

void repl(string[string] opts) {
    State state = new State(opts["std"]);
    while (true) {
        write(">>> ");
        string code = readln;
        ParseString str = new ParseString(code);
        Program prog = new Program(str);
        Value got = state.run(prog);
        if (got.type != Type.NULL) {
            writeln(got);
        }
    }
}
