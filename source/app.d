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
        "std": "stdlib",
    ];
    foreach (i; args) {
        if (i.length > 2 && i[0..2] == "--") {
            size_t spl = 0;
            foreach (j; 2..i.length) {
                if (i[j] == '=') {
                    spl = j;
                    break;
                }
            }
            if (spl == 0) {
                opts[i[2..spl]] = "true";
            }
            else {
                opts[i[2..spl]] = i[spl+1..$];
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
        repl(opts);
    }
    else {
        foreach (i; names) {
            ParseString code = new ParseString(cast(string) read(i));
            Program prog = new Program(code);
            State state = new State(opts["std"]);
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
