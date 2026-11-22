const std = @import("std");

const stdout = std.Io.File.stdout();
const stdin = std.Io.File.stdin();

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const input = try readUserInput(allocator, io);
    defer allocator.free(input);

    try printInput(input, allocator, io);
}

pub fn readUserInput(allocator: std.mem.Allocator, io: std.Io) ![]u8 {
    const buf: []u8 = try allocator.alloc(u8, 1024); // 1kb
    defer allocator.free(buf);

    var reader = stdin.reader(io, buf);
    const line = try reader.interface.takeDelimiter('\n') orelse return error.EndOfStream;

    return try allocator.dupe(u8, line);
}

pub fn printInput(input: []const u8, allocator: std.mem.Allocator, io: std.Io) !void {
    const buf: []u8 = try allocator.alloc(u8, 1024);
    defer allocator.free(buf);

    var writer = stdout.writer(io, buf);
    _ = try writer.interface.writeAll(input);
    _ = try writer.interface.writeByte('\n'); // newline
    try writer.flush();
}
