// util.zig

const std = @import("std");
const game = @import("game.zig");
const zg = @import("ziglyph");
const mibu = @import("mibu");

pub fn get_words(allocator: std.mem.Allocator, file_contents: []const u8) ![][]const u21 {
    var lines = std.mem.split(u8, file_contents, &[_]u8{'\n'});
    var word_list = std.ArrayList([]const u21).init(allocator);
    defer word_list.deinit();

    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \r");
        if (trimmed.len > 0) {
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
        out[i] = @as(u21, c);
        i += 1;
    }
    return out;
}

pub fn build_board(allocator: std.mem.Allocator, rows: usize, cols: usize) ![][]game.CharacterState {
    var board = try allocator.alloc([]game.CharacterState, rows);

    for (0..rows) |r| {
        board[r] = try allocator.alloc(game.CharacterState, cols);
        for (0..cols) |c| {
            board[r][c] = game.CharacterState{
                .letter = '_',
                .status = 0,
            };
        }
    }
    return board;
}

pub fn update_rboard(rboard: [][]u21, guess_word: []const u21, current_row: usize, win: bool) !void {
    if (win) {
        return;
    }
    for (guess_word, 0..) |char, col| {
        rboard[current_row][col] = zg.toLower(char);
    }
}

pub fn check_char(sboard: [][]game.CharacterState, guess_word: []const u21, target_word: []const u21, current_row: usize) !void {
    for (guess_word, 0..) |guess, i| {
        var status: i8 = 0;

        if (guess == target_word[i]) {
            status = 1;
        } else {
            for (target_word, 0..) |target, j| {
                if (guess == target and i != j) {
                    status = -1;
                    break;
                }
            }
        }
        sboard[current_row][i] = game.CharacterState{
            .letter = zg.toUpper(guess),
            .status = status,
        };
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

pub fn check_dup_word(guess_word: []const u21, words: [][]const u21, current_row: usize) bool {
    for (0..current_row) |row| {
        if (std.mem.eql(u21, guess_word, words[row])) {
            return true;
        }
    }
    return false;
}
