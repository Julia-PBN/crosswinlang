const std = @import("std");
const ArrayList = std.ArrayList;
const Writer = std.io.Writer;

const Format = @import("misc.zig").Format;

const activeTag = std.meta.activeTag;

pub const KeyAtom = union(enum) {
    const Self = @This();

    LITTERAL: []const u8,
    VAL: []const u8,

    pub fn dump(self: Self, w: anytype, format: Format) void {
        _ = format;
        switch (activeTag(self)) {
            .LITTERAL => {
                w.print("{s}", .{self.LITTERAL}) catch unreachable;
            },
            .VAL => {
                w.print("${s}", .{self.VAL}) catch unreachable;
            },
        }
    }
};

pub const Key = union(enum) {
    const Self = @This();
    ATOM: KeyAtom,
    AND: ArrayList(KeyAtom),

    pub fn dump(self: Self, w: anytype, format: Format) void {
        switch (activeTag(self)) {
            .ATOM => {
                self.ATOM.dump(w, format);
            },
            .AND => {
                switch (format) {
                    .I3, .SWAY, .HYPERLAND => {
                        const v = self.AND.items;
                        const len = v.len;
                        for (0..len - 1) |i| {
                            v[i].dump(w, format);
                            w.print("+", .{}) catch unreachable;
                        }
                        v[len - 1].dump(w, format);
                    },
                }
            },
        }
    }
};

pub const CommandAtom = union(enum) {
    const Self = @This();
    LITTERAL: []const u8,
    VAL: []const u8,

    pub fn dump(self: Self, w: anytype, format: Format) void {
        switch (self) {
            .LITTERAL => {
                w.print("{s}", .{self.LITTERAL}) catch unreachable;
            },
            .VAL => {
                switch (format) {
                    .I3, .SWAY, .HYPERLAND => {
                        w.print("${s}", .{self.VAL}) catch unreachable;
                    },
                }
            },
        }
    }
};

pub const Command = union(enum) {
    const Self = @This();

    CMD: ArrayList(CommandAtom),
    PIPE: struct { left: *Command, right: *Command },
    AND: struct { left: *Command, right: *Command },

    pub fn dump(self: Self, w: anytype, format: Format) void {
        switch (activeTag(self)) {
            .CMD => {
                switch (format) {
                    .I3, .SWAY, .HYPERLAND => {
                        const len = self.CMD.items.len;
                        for (0..len - 1) |i| {
                            self.CMD.items[i].dump(w, format);
                            w.print(" ", .{}) catch unreachable;
                        }
                        self.CMD.items[len - 1].dump(w, format);
                    },
                }
            },
            .PIPE => {
                switch (format) {
                    .I3, .SWAY => {
                        self.PIPE.left.dump(w, format);
                        w.print(" | ", .{}) catch unreachable;
                        self.PIPE.right.dump(w, format);
                    },
                    .HYPERLAND => {
                        self.PIPE.left.dump(w, format);
                        w.print(" || ", .{}) catch unreachable;
                        self.PIPE.right.dump(w, format);
                    },
                }
            },
            .AND => {
                switch (format) {
                    .I3, .SWAY, .HYPERLAND => {
                        self.AND.left.dump(w, format);
                        w.print(" && ", .{}) catch unreachable;
                        self.AND.right.dump(w, format);
                    },
                }
            },
        }
    }
};

pub const Expr = union(enum) {
    const Self = @This();

    BIND: struct {
        to: Key,
        value: *Expr,
    },
    MODE: struct {
        name: []const u8,
        environment: *Expr, // TODO! assert that it is a BLOCK varient
    },
    EXEC: Command,
    SET: struct {
        to: []const u8,
        val: []const u8,
    },
    BLOCK: ArrayList(Expr),

    pub fn dump(self: Self, w: anytype, format: Format) void {
        self._dump(w, format, 0);
    }

    fn _dump(self: Self, w: anytype, format: Format, identation: usize) void {
        switch (activeTag(self)) {
            .BIND => {
                for (0..identation) |_| {
                    w.print("\t", .{}) catch unreachable;
                }
                switch (format) {
                    .I3, .SWAY => {
                        w.print("bindsym ", .{}) catch unreachable;
                        self.BIND.to.dump(w, format);
                        w.print(" ", .{}) catch unreachable;
                        self.BIND.value._dump(w, format, 0);
                    },
                    .HYPERLAND => {
                        w.print("bind = ", .{}) catch unreachable;
                        self.BIND.to.dump(w, format);
                        w.print(", ", .{}) catch unreachable;
                        self.BIND.value._dump(w, format, 0);
                    },
                }
            },

            .MODE => {
                for (0..identation) |_| {
                    w.print("\t", .{}) catch unreachable;
                }
                switch (format) {
                    .I3, .SWAY => {
                        w.print("mode {s} {c}\n", .{ self.MODE.name, '{' }) catch unreachable;
                        self.MODE.environment._dump(w, format, identation + 1);
                        for (0..identation) |_| {
                            w.print("\t", .{}) catch unreachable;
                        }
                        w.print("{c}\n", .{'}'}) catch unreachable;
                    },
                    .HYPERLAND => {
                        w.print("submap = {s}\n", .{self.MODE.name}) catch unreachable;
                        self.MODE.environment._dump(w, format, identation + 1);
                        for (0..identation) |_| {
                            w.print("\t", .{}) catch unreachable;
                        }
                        w.print("submap = reset\n", .{}) catch unreachable;
                    },
                }
            },

            .EXEC => {
                for (0..identation) |_| {
                    w.print("\t", .{}) catch unreachable;
                }
                switch (format) {
                    .I3, .SWAY => {
                        w.print("exec ", .{}) catch unreachable;
                        self.EXEC.dump(w, format);
                        w.print("\n", .{}) catch unreachable;
                    },
                    .HYPERLAND => {
                        w.print("exec, ", .{}) catch unreachable;
                        self.EXEC.dump(w, format);
                        w.print("\n", .{}) catch unreachable;
                    },
                }
            },

            .SET => {
                for (0..identation) |_| {
                    w.print("\t", .{}) catch unreachable;
                }
                switch (format) {
                    .I3, .SWAY => {
                        w.print("set ${s} {s}\n", .{ self.SET.to, self.SET.val }) catch unreachable;
                    },
                    .HYPERLAND => {
                        w.print("${s} = {s}\n", .{ self.SET.to, self.SET.val }) catch unreachable;
                    },
                }
            },

            .BLOCK => {
                for (self.BLOCK.items) |e| {
                    e._dump(w, format, identation);
                }
            },
        }
    }
};
