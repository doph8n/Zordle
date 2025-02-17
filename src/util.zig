// util.zig

const std = @import("std");
const zg = @import("ziglyph");
const mibu = @import("mibu");

pub fn get_words(allocator: std.mem.Allocator, file_contents: []const u8) ![][]const u21 {
    // Split the file at newline characters.
    // Note: For splitting with u21 you must supply a delimiter of type []const u21.
    // However, since file_contents is still UTF-8, we work with u8 here.
    var lines = std.mem.split(u8, file_contents, &[_]u8{'\n'});
    var word_list = std.ArrayList([]const u21).init(allocator);
    defer word_list.deinit();

    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \r");
        if (trimmed.len > 0) {
            // Convert trimmed ASCII text to a u21 array.
            const word = try convertToU21(allocator, trimmed);
            try word_list.append(word);
        }
    }
    return word_list.toOwnedSlice();
}
fn convertToU21(allocator: std.mem.Allocator, text: []const u8) ![]const u21 {
    var out = try allocator.alloc(u21, text.len);
    var i: usize = 0;
    for (text) |c| {
        // For ASCII, casting with @as is safe.
        out[i] = @as(u21, c);
        i += 1;
    }
    return out;
}

pub fn build_board(allocator: std.mem.Allocator, rows: usize, cols: usize) ![][]u21 {
    var board = try allocator.alloc([]u21, rows);

    for (0..rows) |r| {
        board[r] = try allocator.alloc(u21, cols);
        for (0..cols) |c| {
            board[r][c] = '_';
        }
    }
    return board;
}

pub fn update_board(real_board: [][]u21, fake_board: [][]u21, guess_word: []const u21, current_row: usize, win: bool) void {
    if (!win) {
        for (guess_word, 0..) |char, col| {
            fake_board[current_row][col] = zg.toUpper(char);
            real_board[current_row][col] = zg.toLower(char);
        }
    } else {
        for (guess_word, 0..) |char, col| {
            fake_board[current_row][col] = zg.toUpper(char);
        }
    }
}

pub fn make_matrix(allocator: std.mem.Allocator, rows: usize, cols: usize) ![][]u21 {
    var board = try allocator.alloc([]u21, rows);

    for (0..rows) |r| {
        board[r] = try allocator.alloc(u21, cols);
    }
    return board;
}

pub fn select_rand_word(words: [][]const u21) ![]const u21 {
    const index = std.crypto.random.intRangeLessThan(usize, 0, words.len);
    return words[index];
}

pub fn check_word(guess_word: []const u21, words: [][]const u21) bool {
    for (words) |word| {
        if (std.mem.eql(u21, guess_word, word)) {
            return true;
        }
    }
    return false;
}
