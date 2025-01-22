const std = @import("std");
const game = @import("game.zig");
const builder = @import("game_builder.zig");

pub fn main() !void {
    var wordle_seed: usize = undefined;
    var hidden_word: [5]u8 = undefined;
    var words_list: [][]u8 = undefined;

    try builder.build_game(&wordle_seed, &hidden_word, &words_list);

    std.debug.print("wordle_seed = {}\n", .{wordle_seed});

    for (hidden_word[0..5]) |c| {
        std.debug.print("{c}", .{c});
    }
    std.debug.print("\n", .{});
}
