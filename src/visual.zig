// Visual.zig

const std = @import("std");
const mibu = @import("mibu");
const posix = std.posix;

const stdin = std.io.getStdIn();
const stdout = std.io.getStdOut();

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

pub fn draw_Zordle(width: u16) !void {
    const writer = std.io.getStdOut().writer();
    const banner = [_][]const u8{
        "╭───────╮",
        "│ Zorde │",
        "╰───────╯",
    };

    const banner_width = 10;
    const start_col = (@as(usize, width) -| banner_width) / 2;

    for (banner, 1..) |line, row| {
        try mibu.cursor.goTo(writer, start_col, row);
        try writer.print("{s}{s}{s}\n", .{ mibu.color.print.fg(.yellow), line, mibu.color.print.reset });
    }
}

pub fn display_board(board: [][]u21, width: u16) !void {
    const writer = std.io.getStdOut().writer();

    const board_width = 18;
    const start_col = (@as(usize, width) -| board_width) / 2;

    try mibu.cursor.goTo(writer, start_col, 4);
    try writer.print("{s}╭───────────────╮{s}", .{ mibu.color.print.fg(.yellow), mibu.color.print.reset });
    for (board, 5..) |line, row| {
        try mibu.cursor.goTo(writer, start_col, row);
        try writer.print("{u}\n", .{line});
    }
    try mibu.cursor.goTo(writer, start_col, 11);
    try writer.print("{s}╰───────────────╯{s}", .{ mibu.color.print.fg(.yellow), mibu.color.print.reset });
}
