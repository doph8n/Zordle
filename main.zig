const std = @import("std");

pub fn line_count(file: std.fs.File) !usize {
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    var count: usize = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |_| {
        count += 1;
    }
    return count;
}

pub fn wordle_array(rows: usize, cols: usize, allocator: std.mem.Allocator) ![][]u8 {
    const wordle_words = try allocator.alloc([]u8, rows);

    // Allocate each row
    for (wordle_words) |*row| {
        row.* = try allocator.alloc(u8, cols);
    }

    return wordle_words;
}

pub fn free_wordle_array(words: [][]u8, allocator: std.mem.Allocator) void {
    for (words) |row| {
        allocator.free(row);
    }
    allocator.free(words);
}

pub fn read_file(file: std.fs.File, words: [][]u8, WORD_LENGTH: usize, total_lines: usize) !void {
    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [1024]u8 = undefined;
    var word_count: usize = 0;
    // Read file line by line
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (word_count < total_lines) {
            @memcpy(words[word_count][0..WORD_LENGTH], line[0..WORD_LENGTH]);
            word_count += 1;
        }
    }
}

pub fn main() !void {
    // Allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    const file = try std.fs.cwd().openFile("wordle-answers-alphabetical.txt", .{});
    defer file.close();

    // Get the line count
    const total_lines = try line_count(file);

    // Create dynamic 2D array
    const WORD_LENGTH = 5;
    const words = try wordle_array(total_lines, WORD_LENGTH, allocator);
    defer free_wordle_array(words, allocator);

    // Reset file cursor to beginning then read file's contents into words
    try file.seekTo(0);
    try read_file(file, words, WORD_LENGTH, total_lines);
}
