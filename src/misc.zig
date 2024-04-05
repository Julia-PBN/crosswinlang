const std = @import("std");
const ArrayList = std.ArrayList;

pub const Position = struct {
    const Self = @This();
    y: usize,
    x: usize,
    actual_position: usize,
    file: [:0]const u8,

    pub fn init(file: [:0]const u8) Self {
        return Self{
            .x = 0,
            .y = 0,
            .actual_position = 0,
            .file = file,
        };
    }

    pub fn advance(self: *Self, char: u8) void {
        self.actual_position += 1;
        if (char == '\n') {
            self.x = 0;
            self.y += 1;
        } else {
            self.x += 1;
        }
    }
};

pub const Format = enum {
    I3,
    SWAY,
    HYPERLAND,
};
