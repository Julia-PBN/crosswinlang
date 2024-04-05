const std = @import("std");
const Lexer = @import("Lexer.zig");
const Parser = @import("Parser.zig");
const ArrayList = std.ArrayList;
const Format = @import("misc.zig").Format;
const memeql = std.mem.eql;

const log = std.log.debug;

fn help(args: [][:0]const u8) void {
    log("wrong usage\n", .{});
    log("{s} <cf_file> (i3|sway|hyperland)\n", .{args[0]});
    log("and btw, it writes on stdout", .{});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();
    const allocator = arena.allocator();
    const args = try std.process.argsAlloc(allocator);
    if (args.len != 3) {
        help(args);
        std.os.exit(1);
    }
    const format_name = args[2];
    var format: Format = undefined;
    if (memeql(u8, format_name, "i3")) {
        format = .I3;
    } else if (memeql(u8, format_name, "sway")) {
        format = .SWAY;
    } else if (memeql(u8, format_name, "hyperland")) {
        format = .HYPERLAND;
    } else {
        log("Format {s} not recognised\n", .{args[2]});
        help(args);
        std.os.exit(1);
    }

    var parser = Parser.init(args[1], allocator);
    parser.parse().dump(format);
}
