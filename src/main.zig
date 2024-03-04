const std = @import("std");

const zargs = @import("zargs");

const WORD_RAW = @embedFile("words");
const WORDS = blk: {
    @setEvalBranchQuota(500000);
    const count = std.mem.count(u8, WORD_RAW, "\n");
    var words: [count + 1][]const u8 = undefined;

    var iter = std.mem.tokenizeScalar(u8, WORD_RAW, '\n');
    var i = 0;
    while (iter.next()) |word| : (i += 1) {
        words[i] = word;
    }
    break :blk words;
};

pub fn main() !void {
    var args = try zargs.currentProcParse(struct {
        password_count: u16 = 1,
        password_word_length: u16 = 4,

        pub const shorthands = .{
            .c = "password_count",
            .l = "password_word_length",
        };
    }, std.heap.page_allocator);
    defer args.deinit();

    const opts = &args.options;

    var rng = std.rand.DefaultPrng.init(blk: {
        var seed: usize = undefined;
        std.os.getrandom(std.mem.asBytes(&seed)) catch unreachable;
        break :blk seed;
    });
    const random = rng.random();

    const stdout = std.io.getStdOut();
    var bw = std.io.bufferedWriter(stdout.writer());
    defer bw.flush() catch unreachable;
    const writer = bw.writer();

    for (0..opts.password_count) |_| {
        var password = std.ArrayList(u8).init(std.heap.page_allocator);
        defer password.deinit();

        for (0..opts.password_word_length) |_| {
            const idx = password.items.len;
            try password.appendSlice(WORDS[random.int(usize) % WORDS.len]);

            password.items[idx] = std.ascii.toUpper(password.items[idx]);
        }

        try writer.print("{s}\n", .{password.items});
    }
}
