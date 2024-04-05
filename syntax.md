# the .cf file format

support for `mode`, `bind`, `set` and `exec`

# syntax

put expression in a mode: `(mode mode_name expression expression ...)`
bind symbol to expression: `(bind key value)`
set symbol to value: `(bind key value)`
exec command: `(exec the command with space)` (for example `(exec ls -lh)`)

strings are going until their end (so you can do `(exec echo "this is fine")`)

and that is the intended way if you want to use ) or ( in a command/name

You can escape " in string using `\"`

# TODO

add support for addition of multiple keys (will probably be `(+ a b)` or `(and a b)`)

add support for getting value of variable, for example to do the i3's `exec $terminal`
will probably be `(exec (val terminal))`

add command to switch to a new mode, will probably be `(switch mode)`

due to hyperland being a bit weird, I need a `&&` and `|` command for true support for exec, but that's for latter, will probably be `(and expr1 expr2)` and `(pipe expr to_expr)`.
