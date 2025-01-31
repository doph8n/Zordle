const std = @import("std");
const visual = @import("visual.zig");

const mibu = @import("mibu");
const events = mibu.events;
const term = mibu.term;
const utils = mibu.utils;

const stdin = std.io.getStdIn();
const stdout = std.io.getStdOut();

pub fn main() !void {
    // Use `stdout.writer()` instead of passing a file descriptor
    try mibu.clear.all(stdout.writer());

    var raw_term = try term.enableRawMode(std.posix.STDIN_FILENO);
    defer raw_term.disableRawMode() catch {};

    while (true) {
        const next = try events.nextWithTimeout(stdin, 10);
        const size = try visual.getTerminalSize();
        std.debug.print("Terminal width={} height={}\n\r", .{ size.width, size.height });
        switch (next) {
            .key => |k| switch (k) {
                .char => |c| try stdout.writer().print("{u}\n\r", .{c}),
                .ctrl => |c| {
                    if (c == 'c') {
                        std.debug.print("Exiting...\n", .{});
                        break;
                    }
                },
                else => try stdout.writer().print("{s}\n\r", .{k}),
            },
            .none => continue,
            else => continue,
        }
    }
}
