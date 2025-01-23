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

pub fn update_board(real_board: [][]u8, fake_board: [][]u8, guess_word: []const u8, current_row: usize, win: bool) void {
    if (!win) {
        for (guess_word, 0..) |char, col| {
            fake_board[current_row][col] = char;
            real_board[current_row][col] = char;
        }
    } else {
        for (guess_word, 0..) |char, col| {
            fake_board[7][col] = std.ascii.toUpper(char);
            fake_board[current_row][col] = std.ascii.toUpper(char);
        }
    }
}

pub fn check_char(board: [][]u8, guess_word: []const u8, target_word: []const u8, current_row: usize) void {
    for (guess_word, 0..) |guess, i| {
        for (target_word, 0..) |target, j| {
            if (target == guess and j == i) {
                board[7][i] = std.ascii.toUpper(guess);
            } else if (target == guess and j != i) {
                board[current_row][i] = std.ascii.toUpper(guess);
            }
        }
    }
}

pub fn make_matrix(allocator: std.mem.Allocator, rows: usize, cols: usize) ![][]u8 {
    var board = try allocator.alloc([]u8, rows);

    for (0..rows) |r| {
        board[r] = try allocator.alloc(u8, cols);
    }
    return board;
}

pub fn build_board(allocator: std.mem.Allocator, rows: usize, cols: usize) ![][]u8 {
    var board = try allocator.alloc([]u8, rows + 2);

    // Allocate each row and initialize values
    for (0..rows) |r| {
        board[r] = try allocator.alloc(u8, cols);
        for (0..cols) |c| {
            board[r][c] = '_';
        }
    }

    // Allocate and initialize the '~' row
    board[rows] = try allocator.alloc(u8, cols);
    for (0..cols) |c| {
        board[rows][c] = '~';
    }

    // Allocate and initialize the 'X' row
    board[rows + 1] = try allocator.alloc(u8, cols);
    for (0..cols) |c| {
        board[rows + 1][c] = 'X';
    }

    return board;
}

pub fn select_rand_word(words: [][]const u8) ![]const u8 {
    const index = std.crypto.random.intRangeLessThan(usize, 0, words.len);
    return words[index];
}

pub fn check_word(guess_word: []const u8, words: [][]const u8) bool {
    for (words) |word| {
        if (std.mem.eql(u8, guess_word, word)) {
            return true;
        }
    }
    return false;
}

pub fn lowercaseMatrix(matrix: [][]u8) void {
    for (matrix) |row| {
        for (row) |*char| {
            char.* = std.ascii.toLower(char.*);
        }
    }
}

pub fn lc_check_word(guess_word: []const u8, words: [][]const u8, allocator: std.mem.Allocator) !bool {
    var lower_words = try allocator.alloc([]u8, words.len);
    defer allocator.free(lower_words);

    for (words, 0..) |word, i| {
        lower_words[i] = try allocator.alloc(u8, word.len);
        for (word, 0..) |c, j| {
            lower_words[i][j] = std.ascii.toLower(c);
        }
    }

    var lower_guess = try allocator.alloc(u8, guess_word.len);
    defer allocator.free(lower_guess);
    for (guess_word, 0..) |c, i| {
        lower_guess[i] = std.ascii.toLower(c);
    }

    for (lower_words) |word| {
        if (std.mem.eql(u8, lower_guess, word)) {
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
        stdout.print("Enter your guess: ", .{}) catch {};

        var buffer: [100]u8 = undefined;
        const input = stdin.readUntilDelimiterOrEof(&buffer, '\n') catch {
            stdout.print("Error reading input. Try again.\n", .{}) catch {};
            continue;
        } orelse {
            stdout.print("Empty input. Try again.\n", .{}) catch {};
            continue;
        };

        const trimmed = std.mem.trim(u8, input, " \r");
        if (trimmed.len != cols) {
            stdout.print("Guess must be {d} letters. Try again.\n", .{cols}) catch {};
            continue;
        }

        const guess = allocator.alloc(u8, cols) catch unreachable;
        for (trimmed, 0..) |char, i| {
            guess[i] = std.ascii.toLower(char);
        }

        return guess;
    }
}
