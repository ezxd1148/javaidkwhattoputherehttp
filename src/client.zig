const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const host: []const u8 = "0.0.0.0";
    const hostName: std.Io.net.HostName = try std.Io.net.HostName.init(host);

    // client struct
    var client: std.http.Client = .{
        .io = io,
        .allocator = allocator,
    };

    const clientConnection = try client.connect(hostName, std.mem.littleToNative(u16, 8080), .plain);
    if (@TypeOf(clientConnection) == std.http.Connection) {
        std.debug.print("Connections working bro", .{});
    }
}
