# the .cf file format

support for `mode`, `bind`, `set` and `exec`

# syntax

put expression in a mode: `(mode mode_name expression expression ...)`
bind symbol to expression: `(bind key expression)`
set symbol to value: `(set key value)`
exec command: `(exec command)` (for example `(exec ls -lh)`)
getting value of a variable v: `(val variable)`
piping two commands: `(pipe cmd1 cmd2)`
and-ing two commands: `(and cmd1 cmd2)`

strings are going until their end (so you can do `(exec echo "this is fine")`)

and that is the intended way if you want to use ) or ( in a command/name

You can escape " in string using `\"`

The EBNF:

```
PROGRAM = BLOCK
BLOCK = EXPR*
EXPR = MODE | BIND | SET | EXEC
MODE = '(' "mode" VAR BLOCK ')'
BIND = '(' "bind" KEY EXEC ')'
SET = '(' "set" VAR (VAR|VAL) ')'
EXEC = '(' "exec" COMMAND ')'
VAR = [^\s"()][^\s()]* | '"' ([^"] | "\\\"")* '"'
VAL = '(' "val" VAR ')'
KEY = KEY_ATOM | AND_KEY
AND_KEY = '(' "and" KEY_ATOM+ ')'
KEY_ATOM = VAR | VAL
COMMAND = CMD | PIPE | AND_COMMAND
PIPE = '(' "pipe" COMMAND COMMAND ')'
AND_COMMAND = '(' "and" COMMAND COMMAND ')'
CMD = '(' "cmd" CMD_ATOM+ ')'
CMD_ATOM = VAR | VAL
```

# TODO

add command to switch to a new mode, will probably be `(switch mode)`
