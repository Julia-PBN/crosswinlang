const Self = @This();
const Token = @import("Token.zig").Token;
const TokenType = @import("Token.zig").TokenType;
const TokenTypeEnum = @typeInfo(TokenType).Union.tag_type.?;
const Position = @import("misc.zig").Position;
const std = @import("std");
const ascii = std.ascii;
const memeql = std.mem.eql;

const log = std.log.info;

file_content: [:0]const u8,
position: Position,
current: Token,
before_par: bool,

pub fn init(file_name: [:0]const u8, file_content: [:0]const u8) Self {
    var lexer = Self{
        .file_content = file_content,
        .position = Position.init(file_name),
        .current = undefined,
        .before_par = false,
    };
    lexer.next();
    return lexer;
}

pub fn top(self: Self) Token {
    return self.current;
}

pub fn pop(self: *Self) Token {
    const tok = self.top();
    self.next();
    return tok;
}

fn advance(self: *Self) void {
    self.position.advance(self.get_char());
}

pub fn check(self: Self, tt: TokenType) bool {
    return self.top().tag() == tt;
}

fn get_char(self: Self) u8 {
    return self.file_content[self.position.actual_position];
}

fn is_eof(self: Self) bool {
    return self.get_char() == 0;
}

fn match(self: *Self, c: u8) bool {
    if (self.get_char() == c) {
        self.advance();
        return true;
    }
    return false;
}

pub fn next_assert(self: *Self, tok: TokenTypeEnum) Token {
    const token = self.top();
    if (token.tag() == tok) {
        self.next();
        return token;
    }
    unreachable;
}

pub fn next_bool(self: *Self, tok: TokenTypeEnum) bool {
    const token = self.top();
    if (token.tag() != tok)
        return false;
    self.next();
    return true;
}

pub fn next(self: *Self) void {
    while (ascii.isWhitespace(self.get_char()))
        self.advance();

    if (self.is_eof()) {
        self.current = Token.init(.EOF, self.position);
        return;
    }

    const pos: Position = self.position;
    if (self.match('"')) {
        self.advance();
        var last_esc = false;
        while (!self.is_eof() and (last_esc or self.get_char() != '"')) {
            last_esc = self.get_char() == '\\' and !last_esc;
            self.advance();
        }
        if (self.is_eof()) {
            log("ERROR: end of file reached from string starting at line {} offset {}", .{ pos.y, pos.x });
            // TODO exit nicely
            unreachable;
        }
        _ = self.match('"');
        const s: []const u8 = self.file_content[pos.actual_position..self.position.actual_position];
        self.current = Token.init(TokenType{ .VAR = s }, pos);
        self.before_par = false;
    } else if (self.match('(')) {
        self.current = Token.init(TokenType.LEFT_PAR, pos);
        self.before_par = true;
    } else if (self.match(')')) {
        self.current = Token.init(TokenType.RIGHT_PAR, pos);
        self.before_par = false;
    } else {
        while (!self.is_eof() and !ascii.isWhitespace(self.get_char()) and self.get_char() != '(' and self.get_char() != ')') {
            self.advance();
        }
        const s: []const u8 = self.file_content[pos.actual_position..self.position.actual_position];
        if (self.before_par) {
            if (memeql(u8, s, "mode")) {
                self.current = Token.init(TokenType.MODE, pos);
            } else if (memeql(u8, s, "bind")) {
                self.current = Token.init(TokenType.BIND, pos);
            } else if (memeql(u8, s, "exec")) {
                self.current = Token.init(TokenType.EXEC, pos);
            } else if (memeql(u8, s, "set")) {
                self.current = Token.init(TokenType.SET, pos);
            } else if (memeql(u8, s, "val")) {
                self.current = Token.init(TokenType.VAL, pos);
            } else if (memeql(u8, s, "and")) {
                self.current = Token.init(TokenType.AND, pos);
            } else if (memeql(u8, s, "pipe")) {
                self.current = Token.init(TokenType.PIPE, pos);
            } else if (memeql(u8, s, "cmd")) {
                self.current = Token.init(TokenType.CMD, pos);
            } else {
                log("Expected command (bind|mode|exec) at line {}, offset {}", .{ pos.y, pos.x });
            }
        } else {
            self.current = Token.init(TokenType{ .VAR = s }, pos);
        }
        self.before_par = false;
    }
}
