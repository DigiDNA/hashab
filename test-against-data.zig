const std = @import("std");
const c = @cImport({
    @cInclude("calcHashAB.h");
});

const json_data = @embedFile("test-data.json");
const rnd_bytes: *const [23]u8 = "ABCDEFGHIJKLMNOPQRSTUVW";

fn hexToBytes(hex: []const u8, out: []u8) !void {
    if (hex.len != out.len * 2) return error.InvalidHexLength;
    for (out, 0..) |*byte, i| {
        const high: u8 = try hexCharToNibble(hex[i * 2]);
        const low: u8 = try hexCharToNibble(hex[i * 2 + 1]);
        byte.* = (high << 4) | low;
    }
}

fn hexCharToNibble(ch: u8) !u8 {
    return switch (ch) {
        '0'...'9' => ch - '0',
        'a'...'f' => ch - 'a' + 10,
        'A'...'F' => ch - 'A' + 10,
        else => error.InvalidHexChar,
    };
}

const TestCase = struct {
    sha1: []const u8,
    uuid: []const u8,
    target: []const u8,
};

var cached_test_cases: ?[]const TestCase = null;

fn getTestCases() []const TestCase {
    if (cached_test_cases) |cases| return cases;
    const parsed = std.json.parseFromSlice(
        []const TestCase,
        std.heap.page_allocator,
        json_data,
        .{},
    ) catch @panic("Failed to parse test data");
    cached_test_cases = parsed.value;
    return parsed.value;
}

fn runTestCase(comptime index: usize) !void {
    const test_case = getTestCases()[index];

    var sha1: [20]u8 = undefined;
    var uuid: [8]u8 = undefined;
    var expected: [57]u8 = undefined;
    var result: [57]u8 = undefined;

    try hexToBytes(test_case.sha1, &sha1);
    try hexToBytes(test_case.uuid, &uuid);
    try hexToBytes(test_case.target, &expected);

    c.calcHashAB(&result, &sha1, &uuid, rnd_bytes);

    try std.testing.expectEqualSlices(u8, &expected, &result);
}

comptime {
    for (0..100) |i| {
        _ = struct {
            const index = i;
            test {
                try runTestCase(index);
            }
        };
    }
}
