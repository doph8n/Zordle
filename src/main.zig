const std = @import("std");
const io = std.io;

const mibu = @import("mibu");
const events = mibu.events;
const term = mibu.term;
const utils = mibu.utils;

pub fn main() !void {
    const stdin = io.getStdIn();
    const stdout = io.getStdOut();

    if (!std.posix.isatty(stdin.handle)) {
        try stdout.writer().print("The current file descriptor is not a referring to a terminal.\n", .{});
        return;
    }

    // Enable terminal raw mode, its very recommended when listening for events
    var raw_term = try term.enableRawMode(stdin.handle);
    defer raw_term.disableRawMode() catch {};

    try stdout.writer().print("Press q or Ctrl-C to exit...\n\r", .{});

    while (true) {
        const next = try events.nextWithTimeout(stdin, 1000);
        switch (next) {
            .key => |k| switch (k) {
                .char => |c| switch (c) {
                    'q' => break,
                    else => try stdout.writer().print("{u}\n\r", .{c}),
                },
                .ctrl => |c| switch (c) {
                    'c' => break,
                    else => try stdout.writer().print("ctrl+{u}\n\r", .{c}),
                },
                else => try stdout.writer().print("{s}\n\r", .{k}),
            },
            .none => try stdout.writer().print("Timeout.\n\r", .{}),

            // ex. mouse events not supported yet
            else => try stdout.writer().print("Event: {any}\n\r", .{next}),
        }
    }

    try stdout.writer().print("Bye bye\n\r", .{});
}
