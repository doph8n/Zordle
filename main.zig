const game = @import("game.zig");

pub fn main() !void {
    try game.wordle();
}
