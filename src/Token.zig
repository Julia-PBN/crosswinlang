const Position = @import("misc.zig").Position;
const activeTag = @import("std").meta.activeTag;

pub const TokenType = union(enum) {
    BIND,
    MODE,
    EXEC,
    SET,
    VAL,
    PIPE,
    AND,
    CMD,
    LEFT_PAR,
    RIGHT_PAR,
    VAR: []const u8,
    EOF,
};

const TokenTypeEnum = @typeInfo(TokenType).Union.tag_type.?;
pub const Token = struct {
    const Self = @This();
    position: Position,
    type: TokenType,

    pub fn init(@"type": TokenType, position: Position) Self {
        return Self{
            .type = @"type",
            .position = position,
        };
    }

    pub fn tag(self: Self) TokenTypeEnum {
        return activeTag(self.type);
    }
};
