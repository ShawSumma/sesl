import std.stdio;
import std.range;
import std.algorithm;
import parser;
import value;

struct Opcode {
    enum Type {
        PASS,
        FUNC,
        PUSH,
        LOAD,
        POP,
        CALL,
        RET,
    }
    Type type;
    size_t value;
    this(Type t, size_t v=0) {
        type = t;
        value = v;
    }
}

class BytecodeCompiler {
    size_t[] stackneed;
    size_t[] size_ts;
    Opcode[] opcodes;
    Value[] values;
    string[] strings;
}

size_t stackNeeded(Command cmd, size_t *tot = null) {
    if (tot == null) {
        tot = new size_t(0);
    }
    foreach (i; cmd.words) {
        if (i.type == Word.Type.CMD) {
            stackNeeded(i.value.cmd, tot);
        }
        else {
            (*tot) ++;
        }
    }
    return *tot;
}

void compile(Word word, ref BytecodeCompiler comp) {
    final switch (word.type) {
        case Word.Type.NUM: {
            size_t count = comp.values.length;
            comp.values ~= newValue(word.value.num);
            comp.opcodes ~= Opcode(Opcode.Type.PUSH, count);
            break;
        }
        case Word.Type.LOAD: {
            size_t count = comp.strings.length;
            comp.strings ~= word.value.load;
            comp.opcodes ~= Opcode(Opcode.Type.LOAD, count);
            break;
        }
        case Word.Type.STR: {
            size_t count = comp.values.length;
            comp.values ~= newValue(word.value.str);
            comp.opcodes ~= Opcode(Opcode.Type.PUSH, count);
            break;
        }
        case Word.Type.CMD: {
            word.value.cmd.compile(comp);
            break;
        }
        case Word.Type.PROG: {
            word.value.prog.compile(comp);
            break;
        }
    }
}

void compile(Command cmd, ref BytecodeCompiler comp) {
    cmd.words[0].compile(comp);
    foreach (i; cmd.words[1..$]) {
        i.compile(comp);
    }
    comp.opcodes ~= Opcode(Opcode.Type.CALL, cmd.words.length - 1);
    comp.stackneed[$-1] = max(cmd.stackNeeded, comp.stackneed[$-1]);
}

void compile(Program prog, ref BytecodeCompiler comp) {
    size_t begin = comp.opcodes.length;
    prog.where = comp.opcodes.length;
    comp.opcodes ~= Opcode(Opcode.Type.FUNC);
    comp.stackneed ~= 1;
    foreach (i; prog.commands) {
        i.compile(comp);
        comp.opcodes ~= Opcode(Opcode.Type.POP);
    }
    if (prog.commands.length == 0) {
        size_t count = comp.values.length;
        comp.values ~= newValue();
        comp.opcodes ~= Opcode(Opcode.Type.PUSH, count);
    }
    else {
        comp.opcodes.popBack;
    }
    comp.opcodes ~= Opcode(Opcode.Type.RET);
    comp.opcodes[begin].value = comp.size_ts.length;
    comp.size_ts ~= comp.opcodes.length-1;
    comp.size_ts ~= comp.stackneed[$-1];
    prog.comp = comp;
    prog.stackneed = comp.stackneed[$-1];
    comp.stackneed.popBack;
}

BytecodeCompiler compile(Program prog) {
    BytecodeCompiler comp = new BytecodeCompiler();
    comp.opcodes ~= Opcode(Opcode.Type.PASS);
    prog.compile(comp);
    comp.opcodes ~= Opcode(Opcode.Type.CALL, 0);
    return comp;
}