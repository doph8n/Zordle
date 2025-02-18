// Visual.zig

const std = @import("std");
const game = @import("game.zig");
const mibu = @import("mibu");
const zg = @import("ziglyph");
const posix = std.posix;

// Mibu patch for macOS
pub fn getTerminalSize() !mibu.term.TermSize {
    var ws: posix.winsize = undefined;
    const err = std.posix.system.ioctl(posix.STDIN_FILENO, posix.T.IOCGWINSZ, @intFromPtr(&ws));
    if (posix.errno(err) != .SUCCESS) {
        return error.IoctlError;
    }
    return mibu.term.TermSize{
        .width = ws.ws_col, // Correct for macOS
        .height = ws.ws_row, // Correct for macOS
    };
}

pub fn draw_Zordle(height: u16, width: u16) !void {
    const writer = std.io.getStdOut().writer();
    const banner = [_][]const u8{
        "╭───────╮",
        "│ Zorde │",
        "╰───────╯",
    };

    const banner_width = 10;
    const window_height = 12;
    const start_col = (@as(usize, width) -| banner_width) / 2;
    const start_row = (@as(usize, height) -| window_height) / 2;

    for (banner, start_row..) |line, row| {
        try mibu.cursor.goTo(writer, start_col, row);
        try writer.print("{s}{s}{s}\n", .{ mibu.color.print.fg(.yellow), line, mibu.color.print.reset });
    }
}

pub fn displayBoard(sboard: [][]game.CharacterState, height: u16, width: u16) !void {
    const writer = std.io.getStdOut().writer();

    const board_width = 14;
    const window_height = 12;
    const start_col = (@as(usize, width) -| board_width) / 2;
    const start_row = (@as(usize, height) -| window_height) / 2;

    try mibu.cursor.goTo(writer, start_col, start_row + 3);
    try writer.print("{s}╭───────────╮{s}\n", .{ mibu.color.print.fg(.yellow), mibu.color.print.reset });

    for (0..sboard.len) |row_index| {
        const row = sboard[row_index];
        try mibu.cursor.goTo(writer, start_col, start_row + 4 + row_index);
        try writer.print("{s}│{s} ", .{ mibu.color.print.fg(.yellow), mibu.color.print.reset });

        for (0..row.len) |col_index| {
            const char_state = row[col_index];
            const letter = char_state.letter;
            const status = char_state.status;

            switch (status) {
                -1 => {
                    try writer.print("{s}{u}{s} ", .{ mibu.color.print.fg(.yellow), letter, mibu.color.print.reset });
                },
                1 => {
                    try writer.print("{s}{u}{s} ", .{ mibu.color.print.fg(.green), letter, mibu.color.print.reset });
                },
                else => {
                    try writer.print("{u} ", .{letter});
                },
            }
        }
        try writer.print("{s}│{s}\n", .{ mibu.color.print.fg(.yellow), mibu.color.print.reset });
    }

    try mibu.cursor.goTo(writer, start_col, start_row + 4 + sboard.len);
    try writer.print("{s}╰───────────╯{s}\n", .{ mibu.color.print.fg(.yellow), mibu.color.print.reset });
}
