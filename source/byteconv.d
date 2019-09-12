import std.stdio;
import std.range;
import parser;
import value;

struct Opcode {
    enum Type {
        PASS,
        FUNC,
        PUSH,
        LOAD,
        POP,
        STORE,
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
    Opcode[] opcodes;
    Value[] values;
    string[] strings;
}

void compile(Word word, ref BytecodeCompiler comp) {
    final switch (word.type) {
        case Word.Type.NUM: {
            size_t count = comp.values.length;
            comp.values ~= Value(word.value.num);
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
            comp.values ~= Value(word.value.str);
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
    if (cmd.words[0].type == Word.Type.STR) {
        size_t count = comp.strings.length;
        comp.strings ~= cmd.words[0].value.str;
        comp.opcodes ~= Opcode(Opcode.Type.LOAD, count);
    }
    else {
        cmd.words[0].compile(comp);
    }
    foreach (i; cmd.words[1..$]) {
        i.compile(comp);
    }
    comp.opcodes ~= Opcode(Opcode.Type.CALL, cmd.words.length - 1);
}

void compile(Program prog, ref BytecodeCompiler comp) {
    size_t begin = comp.opcodes.length;
    comp.opcodes ~= Opcode(Opcode.Type.FUNC);
    foreach (i; prog.commands) {
        i.compile(comp);
        comp.opcodes ~= Opcode(Opcode.Type.POP);
    }
    if (prog.commands.length == 0) {
        size_t count = comp.values.length;
        comp.values ~= Value();
        comp.opcodes ~= Opcode(Opcode.Type.PUSH, count);
    }
    else {
        comp.opcodes.popBack;
    }
    comp.opcodes ~= Opcode(Opcode.Type.RET);
    comp.opcodes[begin].value = comp.opcodes.length-1;
}

BytecodeCompiler compile(Program prog) {
    BytecodeCompiler comp = new BytecodeCompiler();
    comp.opcodes ~= Opcode(Opcode.Type.PASS);
    prog.compile(comp);
    comp.opcodes ~= Opcode(Opcode.Type.CALL, 0);
    return comp;
}