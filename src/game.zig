const Game = struct {
    board: [][]u8,
    word_list: [][]const u8,
    target_word: []const u8,
    guesses_remaining: u8,
    current_row: usize,
    win: bool,
};
