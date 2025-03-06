const std = @import("std");
const zbench = @import("zbench");

const data = @import("data.zig");

const test_data = data.test2;

const lev_single_fn = fn (alloc: ?std.mem.Allocator, str1: []const u8, str2: []const u8) usize;
// const lev_multiple_fn = fn (alloc: ?std.mem.Allocator, data: [][2][]const u8) usize;

const LevSingleBench = struct {
    fun: *const lev_single_fn,

    fn init(fun: *const lev_single_fn) LevSingleBench {
        return .{ .fun = fun };
    }

    pub fn run(self: LevSingleBench, alloc: std.mem.Allocator) void {
        for (test_data) |item| {
            std.mem.doNotOptimizeAway(self.fun(alloc, item[0], item[1]));
        }
    }
};

// const LevMultipleBench = struct {
//     fun: *const lev_multiple_fn,
//
//     fn init(fun: *const lev_multiple_fn) LevMultipleBench {
//         return .{ .fun = fun };
//     }
//
//     pub fn run(self: LevMultipleBench, alloc: std.mem.Allocator) void {
//         std.mem.doNotOptimizeAway(self.fun(alloc, test_data));
//     }
// };

pub fn main() !void {
    const stdout = std.io.getStdOut().writer();
    var bench = zbench.Benchmark.init(std.heap.page_allocator, .{});
    defer bench.deinit();

    try bench.addParam("Levenshtein single recursive", &LevSingleBench.init(&levSingleRec), .{});
    try bench.addParam("Levenshtein single full matrix", &LevSingleBench.init(&levSingleFullMatrix), .{});
    try bench.addParam("Levenshtein single part matrix", &LevSingleBench.init(&levSinglePartMatrix), .{});

    try stdout.writeAll("\n");
    try bench.run(stdout);
}

test "Lev Single Recursive" {
    const res = levSingleRec(null, "kitten", "sitting");
    errdefer std.debug.panic("Res: {}", .{res});

    try std.testing.expect(res == 3);
}

fn levSingleRec(_: ?std.mem.Allocator, str1: []const u8, str2: []const u8) usize {
    if (str1.len == 0)
        return str2.len;

    if (str2.len == 0)
        return str1.len;

    if (str1[0] == str2[0])
        return levSingleRec(null, str1[1..], str2[1..]);

    return 1 + @min(
        levSingleRec(null, str1[1..], str2),
        levSingleRec(null, str1, str2[1..]),
        levSingleRec(null, str1[1..], str2[1..]),
    );
}

test "Lev Single Full Matrix" {
    const alloc = std.testing.allocator;

    const res = levSingleFullMatrix(alloc, "kitten", "sitting");
    errdefer std.debug.panic("Res: {}", .{res});

    try std.testing.expect(res == 3);
}

fn levSingleFullMatrix(_alloc: ?std.mem.Allocator, str1: []const u8, str2: []const u8) usize {
    var arena = std.heap.ArenaAllocator.init(_alloc.?);
    defer arena.deinit();

    const alloc = arena.allocator();

    var mat = alloc.alloc([]usize, str2.len) catch std.debug.panic("Out of memory!", .{});
    for (mat) |*arr| {
        arr.* = alloc.alloc(usize, str1.len) catch std.debug.panic("Out of memory!", .{});
        @memset(arr.*, 0);
    }

    for (mat, 1..) |*item, i| {
        item.*[0] = i;
    }

    for (mat[0], 1..) |*item, i| {
        item.* = i;
    }

    for (1..str1.len) |ind1| {
        for (1..str2.len) |ind2| {
            var subcost: usize = 1;
            if (str1[ind1] != str2[ind2]) {
                subcost = 0;
            }

            mat[ind2][ind1] = @min(
                mat[ind2 - 1][ind1] + 1,
                mat[ind2][ind1 - 1] + 1,
                mat[ind2 - 1][ind1 - 1] + subcost,
            );
        }
    }

    return mat[str2.len - 1][str1.len - 1];
}

test "Lev Single Part Matrix" {
    const alloc = std.testing.allocator;

    const res = levSinglePartMatrix(alloc, "kitten", "sitting");
    errdefer std.debug.panic("Res: {}", .{res});

    try std.testing.expect(res == 3);
}

fn levSinglePartMatrix(_alloc: ?std.mem.Allocator, str1: []const u8, str2: []const u8) usize {
    var arena = std.heap.ArenaAllocator.init(_alloc.?);
    defer arena.deinit();

    const alloc = arena.allocator();

    var v0: []usize = alloc.alloc(usize, str2.len) catch std.debug.panic("Out of memory", .{});
    var v1: []usize = alloc.alloc(usize, str2.len) catch std.debug.panic("Out of memory", .{});

    for (v0, 0..) |*item, idx|
        item.* = idx;

    for (0..str1.len - 1) |i| {
        v1[0] = i;

        for (0..str2.len - 1) |j| {
            const delCost = v0[j + 1] + 1;
            const insCost = v1[j] + 1;

            const subCost = if (str1[i] == str2[j]) v0[j] else v0[j] + 1;

            v1[j + 1] = @min(delCost, insCost, subCost);
        }

        const swap = v0;
        v0 = v1;
        v1 = swap;
    }

    return v0[v0.len - 1];
}
