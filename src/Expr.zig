const std = @import("std");
const ArrayList = std.ArrayList;

const Format = @import("misc.zig").Format;

const activeTag = std.meta.activeTag;

pub const KeyAtom = union(enum) {
    const Self = @This();

    LITTERAL: []const u8,
    VAL: []const u8,

    pub fn dump(self: Self, format: Format) void {
        _ = format;
        switch (activeTag(self)) {
            .LITTERAL => {
                std.debug.print("{s}", .{self.LITTERAL});
            },
            .VAL => {
                std.debug.print("${s}", .{self.VAL});
            },
        }
    }
};

pub const Key = union(enum) {
    const Self = @This();
    ATOM: KeyAtom,
    AND: ArrayList(KeyAtom),

    pub fn dump(self: Self, format: Format) void {
        switch (activeTag(self)) {
            .ATOM => {
                self.ATOM.dump(format);
            },
            .AND => {
                switch (format) {
                    .I3, .SWAY, .HYPERLAND => {
                        const v = self.AND.items;
                        const len = v.len;
                        for (0..len - 1) |i| {
                            v[i].dump(format);
                            std.debug.print("+", .{});
                        }
                        v[len - 1].dump(format);
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

    pub fn dump(self: Self, format: Format) void {
        switch (self) {
            .LITTERAL => {
                std.debug.print("{s}", .{self.LITTERAL});
            },
            .VAL => {
                switch (format) {
                    .I3, .SWAY, .HYPERLAND => {
                        std.debug.print("${s}", .{self.VAL});
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

    pub fn dump(self: Self, format: Format) void {
        switch (activeTag(self)) {
            .CMD => {
                switch (format) {
                    .I3, .SWAY, .HYPERLAND => {
                        const len = self.CMD.items.len;
                        for (0..len - 1) |i| {
                            self.CMD.items[i].dump(format);
                            std.debug.print(" ", .{});
                        }
                        self.CMD.items[len - 1].dump(format);
                    },
                }
            },
            .PIPE => {
                switch (format) {
                    .I3, .SWAY => {
                        self.PIPE.left.dump(format);
                        std.debug.print(" | ", .{});
                        self.PIPE.right.dump(format);
                    },
                    .HYPERLAND => {
                        self.PIPE.left.dump(format);
                        std.debug.print(" || ", .{});
                        self.PIPE.right.dump(format);
                    },
                }
            },
            .AND => {
                switch (format) {
                    .I3, .SWAY, .HYPERLAND => {
                        self.AND.left.dump(format);
                        std.debug.print(" && ", .{});
                        self.AND.right.dump(format);
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

    // TODO! take a writer to be able to buffer it
    pub fn dump(self: Self, format: Format) void {
        self._dump(format, 0);
    }

    fn _dump(self: Self, format: Format, identation: usize) void {
        switch (activeTag(self)) {
            .BIND => {
                for (0..identation) |_| {
                    std.debug.print("\t", .{});
                }
                switch (format) {
                    .I3, .SWAY => {
                        std.debug.print("bindsym ", .{});
                        self.BIND.to.dump(format);
                        std.debug.print(" ", .{});
                        self.BIND.value._dump(format, 0);
                    },
                    .HYPERLAND => {
                        std.debug.print("bind = ", .{});
                        self.BIND.to.dump(format);
                        std.debug.print(", ", .{});
                        self.BIND.value._dump(format, 0);
                    },
                }
            },

            .MODE => {
                for (0..identation) |_| {
                    std.debug.print("\t", .{});
                }
                switch (format) {
                    .I3, .SWAY => {
                        std.debug.print("mode {s} {c}\n", .{ self.MODE.name, '{' });
                        self.MODE.environment._dump(format, identation + 1);
                        for (0..identation) |_| {
                            std.debug.print("\t", .{});
                        }
                        std.debug.print("{c}\n", .{'}'});
                    },
                    .HYPERLAND => {
                        std.debug.print("submap = {s}\n", .{self.MODE.name});
                        self.MODE.environment._dump(format, identation + 1);
                        for (0..identation) |_| {
                            std.debug.print("\t", .{});
                        }
                        std.debug.print("submap = reset\n", .{});
                    },
                }
            },

            .EXEC => {
                for (0..identation) |_| {
                    std.debug.print("\t", .{});
                }
                switch (format) {
                    .I3, .SWAY => {
                        std.debug.print("exec ", .{});
                        self.EXEC.dump(format);
                        std.debug.print("\n", .{});
                    },
                    .HYPERLAND => {
                        std.debug.print("exec, ", .{});
                        self.EXEC.dump(format);
                        std.debug.print("\n", .{});
                    },
                }
            },

            .SET => {
                for (0..identation) |_| {
                    std.debug.print("\t", .{});
                }
                switch (format) {
                    .I3, .SWAY => {
                        std.debug.print("set ${s} {s}\n", .{ self.SET.to, self.SET.val });
                    },
                    .HYPERLAND => {
                        std.debug.print("${s} = {s}\n", .{ self.SET.to, self.SET.val });
                    },
                }
            },

            .BLOCK => {
                for (self.BLOCK.items) |e| {
                    e._dump(format, identation);
                }
            },
        }
    }
};
