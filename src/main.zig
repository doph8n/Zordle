const std = @import("std");
const visual = @import("visual.zig");

const mibu = @import("mibu");
const events = mibu.events;
const term = mibu.term;
const utils = mibu.utils;

const stdin = std.io.getStdIn();
const stdout = std.io.getStdOut();

pub fn main() !void {
    try mibu.clear.all(stdout);

    var raw_term = try term.enableRawMode(stdin.handle);
    defer raw_term.disableRawMode() catch {};

    while (true) {
        const next = try events.next(stdin);
        switch (next) {
            .key => |k| switch (k) {
                .char => |c| switch (c) {
                    else => try stdout.writer().print("{u}\n\r", .{c}),
                },
                .ctrl => |c| {
                    if (c == 'c') {
                        std.debug.print("Exiting...\n", .{});
                        break;
                    }
                },
                else => try stdout.writer().print("{s}\n\r", .{k}),
            },
            .resize => {
                const size = try visual.getTerminalSize();
                std.debug.print("Terminal resized: width={} height={}\n", .{ size.width, size.height });
            },
            else => {
                std.debug.print("Unhandled event: {}\n", .{next});
            },
        }
    }
}
