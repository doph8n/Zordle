// main.zig

const std = @import("std");
const visual = @import("visual.zig");
const game = @import("game.zig");
const util = @import("util.zig");
const zg = @import("ziglyph");
const mibu = @import("mibu");
const events = mibu.events;
const term = mibu.term;

const stdin = std.io.getStdErr();
const writer = std.io.getStdOut().writer();

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

    try mibu.clear.all(writer);
    var size = try visual.getTerminalSize();
    try visual.draw_Zordle(size.height, size.width);
    try visual.displayBoard(Zorde.sboard, size.height, size.width);

    try mibu.cursor.hide(writer);
    var raw_term = try term.enableRawMode(std.posix.STDIN_FILENO);
    defer raw_term.disableRawMode() catch {};

    while (Zorde.guesses_remaining > 0 and !Zorde.win) {
        const next = try events.nextWithTimeout(stdin, 16);
        const newSize = try visual.getTerminalSize();
        var guess: []const u21 = undefined;
        if (newSize.width != size.width or newSize.height != size.height) {
            size = newSize;
            try mibu.clear.all(writer);
            try visual.draw_Zordle(newSize.height, newSize.width);
            try visual.displayBoard(Zorde.sboard, size.height, size.width);

            // try mibu.cursor.goTo(writer, 0, newSize.height - 2);
            // try writer.print("{u}", .{Zorde.target_word});
        }
        switch (next) {
            .key => |k| switch (k) {
                .char => |c| {
                    if (Zorde.current_col < cols and c != ' ') {
                        Zorde.rboard[Zorde.current_row][Zorde.current_col] = zg.toLower(c);
                        Zorde.sboard[Zorde.current_row][Zorde.current_col] = game.CharacterState{
                            .letter = zg.toUpper(c),
                            .status = 0,
                        };
                        Zorde.current_col += 1;
                        try visual.displayBoard(Zorde.sboard, size.height, size.width);
                    } else {
                        continue;
                    }
                },
                .ctrl => |c| {
                    if (c == 'c') {
                        try mibu.cursor.goTo(writer, 0, newSize.height - 1);
                        try visual.draw_Zordle(newSize.height, newSize.width);
                        try visual.displayBoard(Zorde.sboard, newSize.height, newSize.width);
                        try writer.print("{s}Exiting...{s}", .{ mibu.color.print.fg(.red), mibu.color.print.reset });
                        break;
                    }
                },
                .enter => {
                    guess = Zorde.rboard[Zorde.current_row];
                    if (Zorde.current_col != cols) {
                        continue;
                    }
                    if (!util.check_word(guess, Zorde.word_list)) {
                        try mibu.clear.all(writer);
                        try visual.draw_Zordle(newSize.height, newSize.width);
                        try visual.displayBoard(Zorde.sboard, newSize.height, newSize.width);
                        try mibu.cursor.goTo(writer, 0, newSize.height - 1);
                        try writer.print("{s}Invalid guess, not in the word list. Try again.{s}", .{ mibu.color.print.fg(.red), mibu.color.print.reset });
                        continue;
                    }
                    if (util.check_dup_word(guess, Zorde.rboard, Zorde.current_row)) {
                        try mibu.clear.all(writer);
                        try visual.draw_Zordle(newSize.height, newSize.width);
                        try visual.displayBoard(Zorde.sboard, newSize.height, newSize.width);
                        try mibu.cursor.goTo(writer, 0, newSize.height - 1);
                        try writer.print("{s}Duplicate guess. Try again.{s}", .{ mibu.color.print.fg(.red), mibu.color.print.reset });
                        continue;
                    }
                    try util.check_char(Zorde.sboard, guess, Zorde.target_word, Zorde.current_row);
                    try util.update_rboard(Zorde.rboard, guess, Zorde.current_row, false);
                    if (std.mem.eql(u21, guess, Zorde.target_word)) {
                        try util.check_char(Zorde.sboard, guess, Zorde.target_word, Zorde.current_row);
                        try util.update_rboard(Zorde.rboard, guess, Zorde.current_row, true);
                        try mibu.clear.all(writer);
                        try visual.draw_Zordle(newSize.height, newSize.width);
                        try visual.displayBoard(Zorde.sboard, newSize.height, newSize.width);
                        Zorde.win = true;
                    }
                    Zorde.current_row += 1;
                    Zorde.guesses_remaining -= 1;
                    Zorde.current_col = 0;

                    try mibu.clear.all(writer);
                    try visual.draw_Zordle(newSize.height, newSize.width);
                    try visual.displayBoard(Zorde.sboard, newSize.height, newSize.width);
                    continue;
                },
                .backspace => {
                    if (Zorde.current_col > 0) {
                        Zorde.current_col -= 1;
                        Zorde.rboard[Zorde.current_row][Zorde.current_col] = '_';
                        Zorde.sboard[Zorde.current_row][Zorde.current_col] = game.CharacterState{
                            .letter = '_',
                            .status = 0,
                        };
                        try visual.displayBoard(Zorde.sboard, newSize.height, newSize.width);
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
        try mibu.cursor.goTo(writer, 0, size.height - 1);
        try writer.print("{s}You won! The word was: {u}{s}", .{ mibu.color.print.fg(.green), Zorde.target_word, mibu.color.print.reset });
    } else {
        try mibu.cursor.goTo(writer, 0, size.height - 1);
        try writer.print("{s}You lost. The word was: {u}{s}", .{ mibu.color.print.fg(.red), Zorde.target_word, mibu.color.print.reset });
    }
}
