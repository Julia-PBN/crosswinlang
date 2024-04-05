# What is crosswinlang

Cross win lang (cwl) is a meta configuration format for windows managers in lisp-style.

It takes only one file and create configuration for your favorite window manager (if it's not the case, feel free to add it)

# Why cwl

Sometimes, your configuration become combersome to maintain if you're using different window managers, so here you have to maintain only one file.

Also I thought of [this meme](https://xkcd.com/927/) when someone asked me if I'd be interested to do that, and that was funny enough for me to do it.

# What cwl is not

Cwl is *not* a programming language, and it's not a compilator from other format to .cwf (cross lang format), although it'd be cool, I think it would be better to have different tools for that.

# How to learn cwl

Look at `syntax.md` and at the files in `examples/`

cwl output on the standard output, and follows the syntax `./cwl (your cwf file) (the format you want)`.

# How to use it

You need a zig compiler, it's quite easy to install (and quite small) so it shouldn't be a problem: https://ziglang.org/learn/getting-started/

and then, you do:

```sh
zig build
```

The output executable is `./zig-out/bin/cwl` (or `/zig-out/bin/cwl.exe` if you are on windows)
