const std = @import("std");

pub fn get_words(allocator: std.mem.Allocator, file_contents: []const u8) ![][]const u8 {
    var lines = std.mem.split(u8, file_contents, &[_]u8{'\n'});
    var word_list = std.ArrayList([]const u8).init(allocator);
    defer word_list.deinit();

    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \r");
        if (trimmed.len > 0) {
            const word = try allocator.dupe(u8, trimmed);
            try word_list.append(word);
        }
    }

    return word_list.toOwnedSlice();
}

pub fn update_board(board: [][]u8, guess: []const u8, current_row: usize) void {
    for (guess, 0..) |char, col| {
        board[current_row][col] = char;
    }
}

pub fn build_board(allocator: std.mem.Allocator, rows: usize, cols: usize) ![][]u8 {
    var board = try allocator.alloc([]u8, rows);
    for (0..rows) |r| {
        board[r] = try allocator.alloc(u8, cols);
        for (0..cols) |c| {
            board[r][c] = '_';
        }
    }
    return board;
}

pub fn select_rand_word(words: [][]const u8) ![]const u8 {
    const index = std.crypto.random.intRangeLessThan(usize, 0, words.len);
    return words[index];
}

pub fn validate_input(guess_word: []const u8, word_list: [][]const u8) bool {
    for (word_list) |word| {
        if (std.mem.eql(u8, guess_word, word)) {
            return true;
        }
    }
    return false;
}

pub fn display_board(board: [][]u8) void {
    for (board) |row| {
        for (row) |cell| {
            std.debug.print("{c} ", .{cell});
        }
        std.debug.print("\n", .{});
    }
}

pub fn get_user_guess(allocator: std.mem.Allocator, cols: usize) []const u8 {
    const stdin = std.io.getStdIn().reader();
    const stdout = std.io.getStdOut().writer();

    while (true) {
        // Prompt the user (ignore stdout errors)
        stdout.print("Enter your guess: ", .{}) catch {};

        // Read input (handle stdin errors)
        var buffer: [100]u8 = undefined;
        const input = stdin.readUntilDelimiterOrEof(&buffer, '\n') catch {
            stdout.print("Error reading input. Try again.\n", .{}) catch {};
            continue;
        } orelse {
            stdout.print("Empty input. Try again.\n", .{}) catch {};
            continue;
        };

        // Trim and lowercase
        const trimmed = std.mem.trim(u8, input, " \r");
        if (trimmed.len != cols) {
            stdout.print("Guess must be {d} letters. Try again.\n", .{cols}) catch {};
            continue;
        }

        // Allocate memory (assume no allocation failure)
        const guess = allocator.alloc(u8, cols) catch unreachable;
        for (trimmed, 0..) |char, i| {
            guess[i] = std.ascii.toLower(char);
        }

        return guess;
    }
}
