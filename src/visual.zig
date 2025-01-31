const std = @import("std");
const mibu = @import("mibu");
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
