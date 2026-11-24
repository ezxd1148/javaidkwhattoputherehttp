const std = @import("std");

pub fn sendMessage(userClient: *std.http.Client, hostName: std.Uri, message: []const u8, allocator: std.mem.Allocator) !void {
    var request = try userClient.request(.POST, hostName, .{ .keep_alive = false });
    defer request.deinit();

    var redirect_buf: [1024]u8 = undefined;
    var transfer_buf: [1024]u8 = undefined;

    const buf = try allocator.dupe(u8, message);
    defer allocator.free(buf);

    try request.sendBodyComplete(buf);

    var response = try request.receiveHead(&redirect_buf);
    std.debug.print("{any}\n", .{@backingInt(response.head.status)});

    const body = response.reader(&transfer_buf);

    _ = try body.discardRemaining();
    if (response.head.status != .ok) return error.SendFailed;
}
