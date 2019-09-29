import std.conv;
import std.string;
import parser;
import value;

Value astValue(Program prog) {
    return prog.commands.astValue;
}

Value astValue(Command[] cmds) {
    Value[] ret;
    foreach (i; cmds) {
        ret ~= i.astValue;
    }
    return newValue(ret);
}

Value astValue(Command cmd) {
    Value[] level;
    foreach (j; cmd.words) {
        level ~= j.astValue;
    }
    return newValue(level);
}

Value astValue(Word word) {
    Value val;
    final switch (word.type) {
        case Word.Type.CMD: {
            val = word.value.cmd.astValue;
            break;
        }
        case Word.Type.LOAD: {
            val = newValue(word.value.load);
            break;
        }
        case Word.Type.NUM: {
            val = newValue(word.value.num);
            break;
        }
        case Word.Type.PROG: {
            val = word.value.prog.astValue;
            break;
        }
        case Word.Type.STR: {
            val = newValue(word.value.load);
            break;
        }
    }
    Value[Value] ret;
    ret[newValue("type")] = newValue(to!string(word.type).toLower);
    ret[newValue("value")] = val;
    return newValue(ret);
}