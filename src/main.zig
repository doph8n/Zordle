// main.zig

const std = @import("std");
const game = @import("game.zig");
const mibu = @import("mibu");
const visual = @import("visual.zig");

const term = mibu.term;
const events = mibu.events;

const stdin = std.io.getStdIn();
const writer = std.io.getStdOut().writer();

pub fn main() !void {
    var playing: bool = true;

    try mibu.clear.all(writer);
    try mibu.cursor.hide(writer);
    var raw_term = try term.enableRawMode(std.posix.STDIN_FILENO);
    defer raw_term.disableRawMode() catch {};

    var size = try visual.getTerminalSize();
    try visual.draw_Zordle(size.height, size.width);

    while (playing) {
        const next = try events.nextWithTimeout(stdin, 16);
        const newSize = try visual.getTerminalSize();
        if (newSize.width != size.width or newSize.height != size.height) {
            size = newSize;
            try mibu.clear.all(writer);
            try visual.draw_Zordle(newSize.height, newSize.width);
        }

        switch (next) {
            .key => |k| switch (k) {
                .char => |c| {
                    if (c == 'q' or c == 'Q') {
                        playing = false;
                        try mibu.cursor.goTo(writer, 0, size.height - 2);
                        try writer.print("{s}Quitting...{s}", .{ mibu.color.print.fg(.red), mibu.color.print.reset });
                        break;
                    } else if (c == 'p' or c == 'P') {
                        try game.Zordle();
                    }
                },
                else => continue,
            },
            .none => continue,
            else => continue,
        }
    }
}
