// main.zig

const game = @import("game.zig");

pub fn main() !void {
    try game.Zordle();
}
