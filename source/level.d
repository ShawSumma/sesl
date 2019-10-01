import std.stdio;
import value;
import states;

alias LocalLevel = Value[string];

LocalLevel createLocalLevel() {
    return null;
}

void setLocal(ref LocalLevel lvl, string name, Value val) {
    lvl[name] = val;
}

void setLocal(ref LocalLevel lvl, string name, Del val) {
    lvl[name] = newValue(ValueFun(val, name));
}

void setLocal(ref LocalLevel lvl, string name, Fun val) {
    lvl[name] = newValue(ValueFun(val, name));
}