const std = @import("std");

pub fn main() !void {
    // var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    // const allocator = gpa.allocator();
    // defer {
    //     const deinit_status = gpa.deinit();
    //     if (deinit_status == .leak) @panic("Memory leaked!");
    // }

    var items = [_][]const u8{"kitten"};

    const search = "sitting";

    fuzzy(@constCast(&items), search);
}

pub fn fuzzy(items: [][]const u8, search: []const u8) void {
    std.debug.print("Search for {s} in: ", .{search});
    for (items) |str|
        std.debug.print("\"{s}\" ", .{str});
    std.debug.print("\n\n", .{});

    var bestDistance: i32 = std.math.maxInt(i32);
    var bestString: []const u8 = "";

    for (items) |str| {
        const dist = levenshteinDistanceRecursive(search, str);

        if (dist < bestDistance) {
            bestString = str;
            bestDistance = dist;
        }
    }

    std.debug.print("Best for \"{s}\" is \"{s}\" with distance {}\n", .{ search, bestString, bestDistance });
}

pub fn levenshteinDistanceRecursive(str1: []const u8, str2: []const u8) i32 {
    if (str1.len == 0)
        return @intCast(str2.len);

    if (str2.len == 0)
        return @intCast(str1.len);

    if (str1[0] == str2[0])
        return levenshteinDistanceRecursive(str1[1..], str2[1..]);

    return 1 + @min(
        levenshteinDistanceRecursive(str1[1..], str2),
        levenshteinDistanceRecursive(str1, str2[1..]),
        levenshteinDistanceRecursive(str1[1..], str2[1..]),
    );
}
