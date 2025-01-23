const std = @import("std");
const util = @import("util.zig");

const GameState = struct {
    real_board: [][]u8,
    seen_board: [][]u8,
    word_list: [][]const u8,
    target_word: []const u8,
    guesses_remaining: u8,
    current_row: usize,
    win: bool,
};

pub fn wordle() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const rows = 6;
    const cols = 5;

    // Open and read the file
    const file = try std.fs.cwd().openFile("wordle-answers-alphabetical.txt", .{});
    defer file.close();

    const file_size = (try file.stat()).size;
    const file_contents = try allocator.alloc(u8, file_size);
    defer allocator.free(file_contents);
    _ = try file.readAll(file_contents);

    var game_state = GameState{
        .real_board = try util.make_matrix(allocator, rows, cols),
        .seen_board = try util.build_board(allocator, rows, cols),
        .word_list = try util.get_words(allocator, file_contents),
        .target_word = undefined,
        .guesses_remaining = 6,
        .current_row = 0,
        .win = false,
    };
    defer {
        // Free real_board
        for (game_state.real_board) |row| {
            allocator.free(row);
        }
        allocator.free(game_state.real_board);

        // Free seen_board rows and then the outer array
        for (game_state.seen_board) |row| {
            allocator.free(row);
        }
        allocator.free(game_state.seen_board);

        // Free word_list
        for (game_state.word_list) |word| {
            allocator.free(word);
        }
        allocator.free(game_state.word_list);
    }

    game_state.target_word = try util.select_rand_word(game_state.word_list);
    //std.debug.print("Target: {s}\n", .{game_state.target_word});

    while (game_state.guesses_remaining > 0 and !game_state.win) {
        util.display_board(game_state.seen_board);

        const guess = util.get_user_guess(allocator, cols);
        defer allocator.free(guess);

        if (!util.check_word(guess, game_state.word_list)) {
            std.debug.print("Invalid guess, not in the word list. Try again.\n", .{});
            continue;
        }
        if (util.check_word(guess, game_state.real_board)) {
            std.debug.print("Duplicate guess. Try again.\n", .{});
            continue;
        }

        util.update_board(game_state.real_board, game_state.seen_board, guess, game_state.current_row, false);
        util.check_char(game_state.seen_board, guess, game_state.target_word, game_state.current_row);

        if (std.mem.eql(u8, guess, game_state.target_word)) {
            util.update_board(game_state.real_board, game_state.seen_board, guess, game_state.current_row, true);
            game_state.win = true;
        }

        game_state.current_row += 1;
        game_state.guesses_remaining -= 1;
    }

    if (game_state.win) {
        std.debug.print("You won! The word was: {s}\n", .{game_state.target_word});
        util.display_board(game_state.seen_board);
    } else {
        std.debug.print("You lost. The word was: {s}\n", .{game_state.target_word});
        util.display_board(game_state.seen_board);
    }
}
