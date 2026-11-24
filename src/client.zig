const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const host: []const u8 = "http://0.0.0.0:8080";
    const hostName: std.Uri = try std.Uri.parse(host);

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

    try request.sendBodiless();

    var response = try request.receiveHead(redirectBuffer);

    const r_reader = response.reader(transferBuffer);
    std.debug.print("Status: {d}\n", .{@backingInt(response.head.status)}); // Backingint is for enum

    var len: usize = 0;
    while (true) {
        if (buf.len - len < 1024) {
            buf = try allocator.realloc(buf, buf.len + 1024);
        }

        const bytes_read = try r_reader.readSliceShort(buf[len..]);

        if (bytes_read == 0) break;
        std.debug.print("{s}", .{buf[len .. len + bytes_read]});

        len += bytes_read;
    }
}
