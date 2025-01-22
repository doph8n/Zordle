const std = @import("std");

pub const Board = struct {
    const Self = @This();
    const MAX_GUESSES: u32 = 6;

    board: [MAX_GUESSES][5]u8,
    guesses: u32,
    status: bool,

    // Initialize the board
    pub fn init() Self {
        return Self{
            .board = std.mem.zeroes([MAX_GUESSES][6]u8),
            .guesses = 0,
            .status = false,
        };
    }
};

pub fn validate_input(guess_word: []const u8, wordle_list: [][]u8) !bool {
    if (guess_word.len != 5) {
        return false;
    }
    for (wordle_list) |word| {
        if (check_word(guess_word, word)) {
            return true;
        }
    }
    return false;
}

pub fn check_word(guess_word: []const u8, hidden_word: []const u8) bool {
    return std.mem.eql(u8, &guess_word, &hidden_word);
}
