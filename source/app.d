import std.stdio;
import std.file;
import std.array;
import std.conv;
import parser;
import states;
import byteconv;
import rtloop;

void main(string[] args) {
    string[string] opts = [
        "mode": "walk",
    ];
    foreach (i; args) {
        if (i.length > 2 && i[0..2] == "--") {
            string[] iall = i[2..$].split("=");
            if (iall.length == 1) {
                opts[iall[0]] = "true";
            }
            else {
                opts[iall[0]] = iall[1];
            }
        }
    }
    string[] names;
    foreach (i; args[1..$]) {
        if (i.length > 2 && i[0..2] == "--") {
            continue;
        }
        names ~= i;
    }
    if (names.length == 0) {
        repl();
    }
    else {
        foreach (i; names) {
            ParseString code = new ParseString(cast(string) read(i));
            Program prog = new Program(code);
            final switch (opts["mode"]) {
                case "interp": {
                    BytecodeCompiler comp = prog.compile();
                    Program runprog = new Program(comp);
                    State state = new State();
                    state.run(runprog);
                    break;
                }
                case "walk": {
                    State state = new State();
                    state.run(prog);
                    break;
                }
            }
        }
    }
}
