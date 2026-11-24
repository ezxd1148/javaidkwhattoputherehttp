const std = @import("std");
const client = @import("client.zig");
const server = @import("server.zig");

const stdout = std.Io.File.stdout();
const stdin = std.Io.File.stdin();

var io: std.Io = undefined;
var allocator: std.mem.Allocator = undefined;

pub fn main(init: std.process.Init) !void {
    allocator = init.gpa;
    io = init.io;

    try printInput("Are you the server or the client?");

    try printInput("1. Client");
    try printInput("2. Server");

    const input = try readUserInput();
    defer allocator.free(input);

    switch (input[0]) {
        '1' => try userClient(),
        '2' => try userServer(),
        else => try printInput("Please pick a valid number!"),
    }
}

pub fn userClient() !void {
    try printInput("Logged in as Client");
}

pub fn userServer() !void {
    try printInput("Logged in as Server");
}

pub fn readUserInput() ![]u8 {
    var buf: [1024]u8 = undefined;

    var reader = stdin.reader(io, &buf);
    const line = try reader.interface.takeDelimiter('\n') orelse return error.EndOfStream;

    return try allocator.dupe(u8, line);
}

pub fn printInput(input: []const u8) !void {
    var buf: [1024]u8 = undefined;

    var writer = stdout.writer(io, &buf);
    const out = &writer.interface;

    _ = try out.writeAll(input);
    _ = try out.writeByte('\n'); // newline
    try out.flush();
}
