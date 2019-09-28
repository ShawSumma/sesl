import level;
import value;
import errors;
import stdlib;

LocalLevel getStdLib(string s) {
    LocalLevel local = createLocalLevel();
    if (s == "stdlib") {
        local.setLocal("nil", newValue());

        local.setLocal("try", &libtry);
        local.setLocal("problem", &libproblem);

        local.setLocal("while", &libwhile);
        local.setLocal("for", &libfor);

        local.setLocal("pass", &pass);
        local.setLocal("proc", &proc);

        local.setLocal("write", &libwrite);
        local.setLocal("echo", &echo);
        
        local.setLocal("true", newValue(true));
        local.setLocal("false", newValue(false));
        local.setLocal("not", &libnot);
        local.setLocal("and", &liband);
        local.setLocal("or", &libor);
        local.setLocal("if", &iflib);

        local.setLocal("into", &libinto);
        local.setLocal("set", &libset);
        local.setLocal("get", &libget);

        local.setLocal("list", &liblist);
        local.setLocal("push", &libpush);
        local.setLocal("strcat", &libstrcat);
        local.setLocal("table", &libtable);
        local.setLocal("length", &liblength);

        local.setLocal("<", &order!"<");
        local.setLocal(">", &order!">");
        local.setLocal("<=", &order!"<=");
        local.setLocal(">=", &order!">=");
        local.setLocal("=", &libequal);
        local.setLocal("!=", &libnotequal);
        
        local.setLocal("+", &libadd);
        local.setLocal("*", &libmul);
        local.setLocal("-", &libsub);
        local.setLocal("/", &libdiv);
        local.setLocal("%", &libmod);
        local.setLocal("pow", &libpow);

        local.setLocal("each", &libforeach);
        local.setLocal("apply", &libapply);
        local.setLocal("fold", &libfold);
        local.setLocal("filter", &libfilter);
        local.setLocal("curry", &libcurry);

        local.setLocal("range", &librange);

        return local;
    }
    throw new Problem("no such standard library " ~ s);
}