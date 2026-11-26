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
                try saveFile(msg_buf[0..n], io, allocator);
            }
            _ = try request.respond("OK\n", .{ .status = .ok });
        }
    }
}

pub fn saveFile(messages: []const u8, io: std.Io, allocator: std.mem.Allocator) !void {
    const cwd = std.Io.Dir.cwd();
    const path = try cwd.openDir(io, ".", .{ .iterate = true });
    defer path.close(io);
    //var iterate = std.Io.Dir.Iterator.init(cwd, .reading);
    var iterate = path.iterate();

    var write_buf: [1024]u8 = undefined;
    //var read_buf: [1024]u8 = undefined;

    var found_file: bool = false;
    var open_file: std.Io.File = undefined;

    // check if the file is present (log.txt)
    while (iterate.reader.state != .finished and found_file != true) {
        const current_file = try iterate.next(io) orelse continue;
        std.debug.print("{s}\n", .{current_file.name});
        if (std.mem.eql(u8, current_file.name, "log.txt")) {
            found_file = true;
            std.debug.print("log.txt present!\n", .{});
        }
    }

    if (found_file == true) {
        open_file = try std.Io.Dir.openFile(path, io, "log.txt", .{ .mode = .read_write });
    } else {
        open_file = try std.Io.Dir.createFile(path, io, "log.txt", .{});
    }

    var writer = open_file.writer(io, &write_buf);
    try writer.seekTo(try open_file.length(io)); // move writer cursor to the end length of log.txt

    defer writer.file.close(io);
    const txt_buf = try allocator.dupe(u8, messages);
    defer allocator.free(txt_buf);

    const n = try writer.interface.write(txt_buf);
    try writer.interface.writeByte('\n');
    try writer.interface.flush();
    std.debug.print("Message {s} sent, with byte {d}\n", .{ txt_buf, n });
}
