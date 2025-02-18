// game.zig

const std = @import("std");
const util = @import("util.zig");

pub const GameState = struct {
    rboard: [][]u21,
    sboard: [][]CharacterState,
    word_list: [][]const u21,
    target_word: []const u21,
    guesses_remaining: u8,
    current_row: usize,
    current_col: usize,
    win: bool,
};

pub const CharacterState = struct {
    letter: u21,
    status: i8,
    // -1 = correct char, wrong spot
    // 0 = default
    // 1 = correct char and spot
};
