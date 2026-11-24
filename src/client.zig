const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const host: []const u8 = "http://0.0.0.0:8080/messages";
    const hostPost: []const u8 = "http://0.0.0.0:8080/send";
    const hostName: std.Uri = try std.Uri.parse(host);
    const hostNamePost: std.Uri = try std.Uri.parse(hostPost);

    const redirectBuffer: []u8 = try allocator.alloc(u8, 1024);
    const transferBuffer: []u8 = try allocator.alloc(u8, 1024);
    var buf: []u8 = try allocator.alloc(u8, 1024);
    defer allocator.free(redirectBuffer);
    defer allocator.free(transferBuffer);
    defer allocator.free(buf);

    // client struct
    var client: std.http.Client = .{
        .io = io,
        .allocator = allocator,
    };
    defer client.deinit();

    var request = try client.request(.GET, hostName, .{});
    defer request.deinit();

    var requestPost = try client.request(.POST, hostNamePost, .{}); // /send
    defer requestPost.deinit();

    try request.sendBodiless();

    try sendMessage(&requestPost, "Hello\n", allocator);

    var response = try request.receiveHead(redirectBuffer);

    const r_reader = response.reader(transferBuffer);
    std.debug.print("Status: {d}\n", .{@backingInt(response.head.status)}); // Backingint is for enum becuz response.head.status is a bunch of enums

    var len: usize = 0;
    while (true) {
        // spoiler, this loop is really not idiomatic
        if (buf.len - len < 1024) {
            buf = try allocator.realloc(buf, buf.len + 1024);
        }

        const bytes_read = try r_reader.readSliceShort(buf[len..]);

        if (bytes_read == 0) break;
        std.debug.print("{s}", .{buf[len .. len + bytes_read]});

        len += bytes_read;
    }
}

pub fn sendMessage(request: *std.http.Client.Request, message: []const u8, allocator: std.mem.Allocator) !void {
    var buf: []u8 = undefined;

    buf = try allocator.dupe(u8, message);
    defer allocator.free(buf);

    try request.sendBodyComplete(buf);
}
