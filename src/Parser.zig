const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;
const TokenType = @import("Token.zig").TokenType;
const Lexer = @import("Lexer.zig");
const Expr = @import("Expr.zig").Expr;
const Command = @import("Expr.zig").Command;
const CommandAtom = @import("Expr.zig").CommandAtom;
const Key = @import("Expr.zig").Key;
const KeyAtom = @import("Expr.zig").KeyAtom;

const Self = @This();

const log = std.log.debug;

lexer: Lexer,
allocator: Allocator,

pub fn init(file_name: [:0]const u8, allocator: Allocator) Self {
    const file_content = allocator.dupeZ(u8, std.fs.cwd().readFileAlloc(allocator, file_name, std.math.maxInt(usize)) catch {
        log("Couldn't open file \"{s}\", does it even exists ?\n", .{file_name});
        unreachable;
    }) catch unreachable; // TODO! say something when bad file

    return Self{
        .lexer = Lexer.init(file_name, file_content),
        .allocator = allocator,
    };
}

pub fn parse(self: *Self) Expr {
    const expr = self.parse_block();
    if (self.lexer.top().tag() != .EOF)
        unreachable;
    return expr;
}

pub fn parse_block(self: *Self) Expr {
    var list = ArrayList(Expr).init(self.allocator);
    while (self.lexer.top().tag() != .RIGHT_PAR and self.lexer.top().tag() != .EOF) {
        list.append(self.parse_expr()) catch unreachable;
    }
    return .{ .BLOCK = list };
}

fn parse_expr(self: *Self) Expr {
    // TODO: expand errors
    _ = self.lexer.next_assert(.LEFT_PAR);
    switch (self.lexer.top().tag()) {
        .BIND => {
            const expr = self.parse_bind();
            _ = self.lexer.next_assert(.RIGHT_PAR);
            return expr;
        },
        .MODE => {
            const expr = self.parse_mode();
            _ = self.lexer.next_assert(.RIGHT_PAR);
            return expr;
        },
        .EXEC => {
            const expr = self.parse_exec();
            _ = self.lexer.next_assert(.RIGHT_PAR);
            return expr;
        },
        .SET => {
            const expr = self.parse_set();
            _ = self.lexer.next_assert(.RIGHT_PAR);
            return expr;
        },

        else => unreachable,
    }
}

fn parse_bind(self: *Self) Expr {
    _ = self.lexer.next_assert(.BIND);
    const to = self.parse_key();
    const value = self.allocator.create(Expr) catch unreachable;
    value.* = self.parse_expr();

    return .{ .BIND = .{ .to = to, .value = value } };
}

fn parse_key(self: *Self) Key {
    if (self.lexer.top().tag() == .VAR) {
        return .{ .ATOM = .{ .LITTERAL = self.lexer.next_assert(.VAR).type.VAR } };
    }
    _ = self.lexer.next_assert(.LEFT_PAR);
    if (self.lexer.top().tag() == .AND) {
        return self.parse_and_key();
    }
    _ = self.lexer.next_assert(.VAL);
    const v = self.lexer.next_assert(.VAR).type.VAR;
    _ = self.lexer.next_assert(.RIGHT_PAR);
    return .{ .ATOM = .{ .VAL = v } };
}

fn parse_and_key(self: *Self) Key {
    _ = self.lexer.next_assert(.AND);
    var list = std.ArrayList(KeyAtom).init(self.allocator);
    while (self.lexer.top().tag() != .EOF and self.lexer.top().tag() != .RIGHT_PAR) {
        list.append(self.parse_key_atom()) catch unreachable;
    }
    _ = self.lexer.next_assert(.RIGHT_PAR);
    return .{ .AND = list };
}

fn parse_key_atom(self: *Self) KeyAtom {
    if (self.lexer.top().tag() == .VAR) {
        return .{ .LITTERAL = self.lexer.next_assert(.VAR).type.VAR };
    }
    _ = self.lexer.next_assert(.LEFT_PAR);
    _ = self.lexer.next_assert(.VAL);
    const v = self.lexer.next_assert(.VAR).type.VAR;
    _ = self.lexer.next_assert(.RIGHT_PAR);
    return .{ .VAL = v };
}

fn parse_mode(self: *Self) Expr {
    _ = self.lexer.next_assert(.MODE);
    const name = self.lexer.next_assert(.VAR).type.VAR;
    const environment_val = self.parse_block();
    const environment = self.allocator.create(@TypeOf(environment_val)) catch unreachable;
    environment.* = environment_val;

    return .{ .MODE = .{ .name = name, .environment = environment } };
}

fn parse_exec(self: *Self) Expr {
    _ = self.lexer.next_assert(.EXEC);
    const command = self.parse_command();
    _ = self.lexer.next_assert(.RIGHT_PAR);
    return .{ .EXEC = command };
}

fn parse_command(self: *Self) Command {
    _ = self.lexer.next_assert(.LEFT_PAR);
    // TODO! handle error
    switch (self.lexer.top().tag()) {
        .CMD => return self.parse_cmd(),
        .AND => return self.parse_and_cmd(),
        .PIPE => return self.parse_pipe_cmd(),
        else => unreachable,
    }
    unreachable;
}

fn parse_cmd(self: *Self) Command {
    _ = self.lexer.next_assert(.CMD);
    var cmds = ArrayList(CommandAtom).init(self.allocator);
    while (self.lexer.top().tag() != .EOF and self.lexer.top().tag() != .RIGHT_PAR)
        cmds.append(self.parse_cmd_atom()) catch unreachable;

    return .{ .CMD = cmds };
}

fn parse_cmd_atom(self: *Self) CommandAtom {
    if (self.lexer.top().tag() == .VAR) {
        return .{ .LITTERAL = self.lexer.next_assert(.VAR).type.VAR };
    }
    // only val possible now
    _ = self.lexer.next_assert(.LEFT_PAR);
    _ = self.lexer.next_assert(.VAL);
    const atom : CommandAtom = .{ .VAL = self.lexer.next_assert(.VAR).type.VAR };

    _ = self.lexer.next_assert(.RIGHT_PAR);
    return atom;
}

fn parse_and_cmd(self: *Self) Command {
    _ = self.lexer.next_assert(.AND);

    const left_val = self.parse_command();
    _ = self.lexer.next_assert(.RIGHT_PAR);

    const right_val = self.parse_command();
    _ = self.lexer.next_assert(.RIGHT_PAR);

    const left = self.allocator.create(Command) catch unreachable;
    left.* = left_val;
    const right = self.allocator.create(Command) catch unreachable;
    right.* = right_val;

    return .{ .AND = .{ .left = left, .right = right } };
}

fn parse_pipe_cmd(self: *Self) Command {
    _ = self.lexer.next_assert(.PIPE);

    const left_val = self.parse_command();
    _ = self.lexer.next_assert(.RIGHT_PAR);

    const right_val = self.parse_command();
    _ = self.lexer.next_assert(.RIGHT_PAR);

    const left = self.allocator.create(Command) catch unreachable;
    left.* = left_val;
    const right = self.allocator.create(Command) catch unreachable;
    right.* = right_val;

    return .{ .PIPE = .{ .left = left, .right = right } };
}
fn parse_set(self: *Self) Expr {
    _ = self.lexer.next_assert(.SET);
    const to = self.lexer.next_assert(.VAR).type.VAR;
    const val = self.lexer.next_assert(.VAR).type.VAR;
    return .{ .SET = .{ .to = to, .val = val } };
}

fn parse_val(self: *Self) Expr {
    _ = self.lexer.next_assert(.VAL);
    const @"var" = self.lexer.next_assert(.VAR).type.VAR;
    return .{ .VAL = @"var" };
}
