// game.zig

const std = @import("std");
const util = @import("util.zig");

pub const GameState = struct {
    rboard: [][]u21,
    sboard: [][]u21,
    word_list: [][]const u21,
    target_word: []const u21,
    guesses_remaining: u8,
    current_row: usize,
    current_col: usize,
    win: bool,
};
