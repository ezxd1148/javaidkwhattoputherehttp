const std = @import("std");
const client = @import("client.zig");
const server = @import("server.zig");

const stdout = std.Io.File.stdout();
const stdin = std.Io.File.stdin();

var io: std.Io = undefined;
var allocator: std.mem.Allocator = undefined;

const host: []const u8 = "http://0.0.0.0:8080/send";
var hostName: std.Uri = undefined;

pub fn main(init: std.process.Init) !void {
    allocator = init.gpa;
    io = init.io;

    try printInput("Are you the server or the client?\n");

    try printInput("1. Client\n");
    try printInput("2. Server\n");

    const input = try readUserInput();
    defer allocator.free(input);

    switch (input[0]) {
        '1' => try userClient(),
        '2' => try userServer(),
        else => try printInput("Please pick a valid number!"),
    }
}

pub fn userClient() !void {
    hostName = try std.Uri.parse(host);
    try printInput("Logged in as Client\n");

    try printInput("Initializing Client...\n");

    // initializing client heerer

    var clientInit: std.http.Client = .{
        .allocator = allocator,
        .io = io,
    };
    defer clientInit.deinit();

    while (true) {
        try printInput("\n> ");
        const userInput = try readUserInput();
        defer allocator.free(userInput);
        if (std.mem.eql(u8, userInput, "q")) {
            break;
        }

        try client.sendMessage(&clientInit, hostName, userInput, allocator);
    }
}

pub fn userServer() !void {
    try printInput("Logged in as Server");

    try server.saveFile("Hello", io, allocator);
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
    try out.flush();
}
