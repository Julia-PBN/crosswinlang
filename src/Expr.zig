const std = @import("std");
const ArrayList = std.ArrayList;
const Writer = std.io.Writer;

const Format = @import("misc.zig").Format;

pub const KeyAtom = union(enum) {
    const Self = @This();

    LITTERAL: []const u8,
    VAL: []const u8,

    pub fn dump(self: Self, w: anytype, format: Format) void {
        _ = format;
        switch (self) {
            .LITTERAL => |e| {
                w.print("{s}", .{e}) catch unreachable;
            },
            .VAL => |e| {
                w.print("${s}", .{e}) catch unreachable;
            },
        }
    }
};

pub const Key = union(enum) {
    const Self = @This();
    ATOM: KeyAtom,
    AND: ArrayList(KeyAtom),

    pub fn dump(self: Self, w: anytype, format: Format) void {
        switch (self) {
            .ATOM => |e| {
                e.dump(w, format);
            },
            .AND => |e| {
                switch (format) {
                    .I3, .SWAY, .HYPERLAND => {
                        const v = e.items;
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
            .LITTERAL => |e| {
                w.print("{s}", .{e}) catch unreachable;
            },
            .VAL => |e| {
                switch (format) {
                    .I3, .SWAY, .HYPERLAND => {
                        w.print("${s}", .{e}) catch unreachable;
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
        switch (self) {
            .CMD => |e| {
                switch (format) {
                    .I3, .SWAY, .HYPERLAND => {
                        const len = e.items.len;
                        for (0..len - 1) |i| {
                            e.items[i].dump(w, format);
                            w.print(" ", .{}) catch unreachable;
                        }
                        e.items[len - 1].dump(w, format);
                    },
                }
            },
            .PIPE => |e| {
                switch (format) {
                    .I3, .SWAY => {
                        e.left.dump(w, format);
                        w.print(" | ", .{}) catch unreachable;
                        e.right.dump(w, format);
                    },
                    .HYPERLAND => {
                        e.left.dump(w, format);
                        w.print(" || ", .{}) catch unreachable;
                        e.right.dump(w, format);
                    },
                }
            },
            .AND => |e| {
                switch (format) {
                    .I3, .SWAY, .HYPERLAND => {
                        e.left.dump(w, format);
                        w.print(" && ", .{}) catch unreachable;
                        e.right.dump(w, format);
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
        switch (self) {
            .BIND => |e| {
                for (0..identation) |_| {
                    w.print("\t", .{}) catch unreachable;
                }
                switch (format) {
                    .I3, .SWAY => {
                        w.print("bindsym ", .{}) catch unreachable;
                        e.to.dump(w, format);
                        w.print(" ", .{}) catch unreachable;
                        e.value._dump(w, format, 0);
                    },
                    .HYPERLAND => {
                        w.print("bind = ", .{}) catch unreachable;
                        e.to.dump(w, format);
                        w.print(", ", .{}) catch unreachable;
                        e.value._dump(w, format, 0);
                    },
                }
            },

            .MODE => |e| {
                for (0..identation) |_| {
                    w.print("\t", .{}) catch unreachable;
                }
                switch (format) {
                    .I3, .SWAY => {
                        w.print("mode {s} {c}\n", .{ e.name, '{' }) catch unreachable;
                        self.MODE.environment._dump(w, format, identation + 1);
                        for (0..identation) |_| {
                            w.print("\t", .{}) catch unreachable;
                        }
                        w.print("{c}\n", .{'}'}) catch unreachable;
                    },
                    .HYPERLAND => {
                        w.print("submap = {s}\n", .{e.name}) catch unreachable;
                        e.environment._dump(w, format, identation + 1);
                        for (0..identation) |_| {
                            w.print("\t", .{}) catch unreachable;
                        }
                        w.print("submap = reset\n", .{}) catch unreachable;
                    },
                }
            },

            .EXEC => |e| {
                for (0..identation) |_| {
                    w.print("\t", .{}) catch unreachable;
                }
                switch (format) {
                    .I3, .SWAY => {
                        w.print("exec ", .{}) catch unreachable;
                        e.dump(w, format);
                        w.print("\n", .{}) catch unreachable;
                    },
                    .HYPERLAND => {
                        w.print("exec, ", .{}) catch unreachable;
                        e.dump(w, format);
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
