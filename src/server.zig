const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    const hostname: []const u8 = "0.0.0.0";
    const port: u16 = 8080;
    const readbuf: []u8 = try allocator.alloc(u8, 1024);
    const writebuf: []u8 = try allocator.alloc(u8, 1024);
    var body_buf: [1024]u8 = undefined;
    var msg_buf: [1024]u8 = undefined;
    defer allocator.free(readbuf);
    defer allocator.free(writebuf);

    const address = try std.Io.net.IpAddress.parse(hostname, port);
    std.debug.print("{any}\n", .{address});

    var server = try address.listen(io, .{});
    defer server.deinit(io);

    while (true) {
        const stream = try server.accept(io);
        defer stream.close(io);

        var reader = stream.reader(io, readbuf);
        var writer = stream.writer(io, writebuf);

        var serverInit = std.http.Server.init(&reader.interface, &writer.interface);

        while (true) {
            var request = serverInit.receiveHead() catch |err| switch (err) {
                error.HttpConnectionClosing => break, //client hung up
                else => {
                    std.debug.print("{any}\n", .{err});
                    break;
                },
            };

            if (request.head.method == .POST and (std.mem.eql(u8, request.head.target, "/send"))) {
                const n_reader = request.readerExpectNone(&body_buf);
                const n = try n_reader.readSliceShort(&msg_buf);
                std.debug.print("{s}\n", .{msg_buf[0..n]});
            }
            _ = try request.respond("Hello\n", .{ .status = .ok });
        }
    }
}
