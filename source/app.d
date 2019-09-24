import std.stdio;
import std.file;
import std.array;
import std.conv;
import parser;
import states;
import byteconv;
import rtloop;
import value;
import errors;

void main(string[] args) {
    string[string] opts = [
        "mode": "interp",
    ];
    foreach (i; args) {
        if (i.length > 2 && i[0..2] == "--") {
            size_t spl = 0;
            foreach (j; 2..i.length) {
                if (j == '=') {
                    spl = j;
                    break;
                }
            }
            if (spl == 0) {
                opts[i[0..spl]] = "true";
            }
            else {
                opts[i[0..spl]] = i[spl+1..$];
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
            State state = new State();
            switch (opts["mode"]) {
                case "interp": {
                    prog.compile;
                    break;
                }
                case "walk": {
                    break;
                }
                default: {
                    SeslThrow(new Problem("mode not known " ~ opts["mode"]));
                }
            }
            state.run(prog);
        }
    }
}
