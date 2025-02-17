// main.zig

const std = @import("std");
const visual = @import("visual.zig");
const game = @import("game.zig");
const util = @import("util.zig");
const zg = @import("ziglyph");
const mibu = @import("mibu");
const events = mibu.events;
const term = mibu.term;

const stdin = std.io.getStdIn();
const stdout = std.io.getStdOut();

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const rows = 6;
    const cols = 5;

    const file = try std.fs.cwd().openFile("wordle-answers-alphabetical.txt", .{});
    defer file.close();

    const file_size = (try file.stat()).size;
    const file_contents = try allocator.alloc(u8, file_size);
    defer allocator.free(file_contents);
    _ = try file.readAll(file_contents);

    var Zorde = game.GameState{
        .rboard = try util.make_matrix(allocator, rows, cols),
        .sboard = try util.build_board(allocator, rows, cols),
        .word_list = try util.get_words(allocator, file_contents),
        .target_word = undefined,
        .guesses_remaining = 6,
        .current_row = 0,
        .current_col = 0,
        .win = false,
    };
    defer {
        for (Zorde.rboard) |row| {
            allocator.free(row);
        }
        allocator.free(Zorde.rboard);

        for (Zorde.sboard) |row| {
            allocator.free(row);
        }
        allocator.free(Zorde.sboard);

        for (Zorde.word_list) |word| {
            allocator.free(word);
        }
        allocator.free(Zorde.word_list);
    }
    Zorde.target_word = try util.select_rand_word(Zorde.word_list);

    try mibu.clear.all(stdout.writer());
    var size = try visual.getTerminalSize();
    try visual.draw_Zordle(size.width);
    try visual.display_board(Zorde.sboard, size.width);

    try mibu.cursor.hide(stdout.writer());
    var raw_term = try term.enableRawMode(std.posix.STDIN_FILENO);
    defer raw_term.disableRawMode() catch {};

    while (Zorde.guesses_remaining > 0 and !Zorde.win) {
        const next = try events.nextWithTimeout(stdin, 16);
        const newSize = try visual.getTerminalSize();
        var guess: []const u21 = undefined;
        if (newSize.width != size.width or newSize.height != size.height) {
            size = newSize;
            try mibu.clear.all(stdout.writer());
            try visual.draw_Zordle(newSize.width);
            try visual.display_board(Zorde.sboard, size.width);
            std.debug.print("{u}", .{Zorde.target_word});
        }

        switch (next) {
            .key => |k| switch (k) {
                .char => |c| {
                    if (Zorde.current_col < cols and c != ' ') {
                        Zorde.rboard[Zorde.current_row][Zorde.current_col] = zg.toLower(c);
                        Zorde.sboard[Zorde.current_row][Zorde.current_col] = zg.toUpper(c);
                        Zorde.current_col += 1;
                        try visual.display_board(Zorde.sboard, size.width);
                    } else {
                        continue;
                    }
                },
                .ctrl => |c| {
                    if (c == 'c') {
                        std.debug.print("Exiting...\n", .{});
                        break;
                    }
                },
                .enter => {
                    guess = Zorde.rboard[Zorde.current_row];
                    if (Zorde.current_col != cols) {
                        continue;
                    }
                    if (!util.check_word(guess, Zorde.word_list)) {
                        std.debug.print("Invalid guess, not in the word list. Try again.\n", .{});
                        continue;
                    }
                    // if (util.check_word(guess, Zorde.rboard)) {
                    //     std.debug.print("Duplicate guess. Try again.\n", .{});
                    //     continue;
                    // }
                    util.update_board(Zorde.rboard, Zorde.sboard, guess, Zorde.current_row, false);
                    if (std.mem.eql(u21, guess, Zorde.target_word)) {
                        util.update_board(Zorde.rboard, Zorde.sboard, guess, Zorde.current_row, true);
                        Zorde.win = true;
                    }
                    Zorde.current_row += 1;
                    Zorde.guesses_remaining -= 1;
                    Zorde.current_col = 0;
                    continue;
                },
                .backspace => {
                    if (Zorde.current_col > 0) {
                        Zorde.current_col -= 1;
                        Zorde.sboard[Zorde.current_row][Zorde.current_col] = '_';
                        try visual.display_board(Zorde.sboard, newSize.width);
                    } else {
                        continue;
                    }
                },
                else => continue,
            },
            .none => continue,
            else => continue,
        }
    }
    if (Zorde.win) {
        std.debug.print("You won! The word was: {u}\n", .{Zorde.target_word});
    } else {
        std.debug.print("You lost. The word was: {u}\n", .{Zorde.target_word});
    }
}
