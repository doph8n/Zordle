const std = @import("std");
const game = @import("game.zig");
const builder = @import("game_builder.zig");
const expect = std.testing.expect;

// Method to check word against solution
pub fn check_word(guess_word: []const u8, hidden_word: []const u8) bool {
    return std.mem.eql(u8, &guess_word, &hidden_word);
}
