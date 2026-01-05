const std = @import("std");
const c = @cImport({
    @cInclude("dlfcn.h");
    @cInclude("calcHashAB.h");
});

const CalcHashABFn = *const fn ([*]u8, [*]u8, [*]u8, [*]const u8) callconv(.c) void;
const rnd_bytes: *const [23]u8 = "ABCDEFGHIJKLMNOPQRSTUVW";

// Fixed seed for deterministic test generation
const TEST_SEED: u64 = 0xDEADBEEFCAFEBABE;

fn getLibraryFn() !CalcHashABFn {
    const handle = c.dlopen("./libhashab32.so", c.RTLD_NOW);
    if (handle == null) {
        return error.LibraryLoadFailed;
    }
    const sym = c.dlsym(handle, "calcHashAB");
    if (sym == null) {
        return error.SymbolNotFound;
    }
    return @ptrCast(@alignCast(sym));
}

fn generateTestInput(comptime test_index: usize) struct { sha1: [20]u8, uuid: [8]u8 } {
    var h = std.crypto.hash.Blake3.init(.{});
    h.update(std.mem.asBytes(&TEST_SEED));
    const idx: u64 = test_index;
    h.update(std.mem.asBytes(&idx));

    var buf: [28]u8 = undefined;
    h.final(&buf);

    return .{
        .sha1 = buf[0..20].*,
        .uuid = buf[20..28].*,
    };
}

fn runTest(comptime test_index: usize) !void {
    const libCalcHashAB = try getLibraryFn();
    const input = generateTestInput(test_index);

    var sha1 = input.sha1;
    var uuid = input.uuid;
    var expected: [57]u8 = undefined;
    var result: [57]u8 = undefined;

    // Call library function (expected)
    libCalcHashAB(&expected, &sha1, &uuid, rnd_bytes);

    // Call C source function (result)
    c.calcHashAB(&result, &sha1, &uuid, rnd_bytes);

    try std.testing.expectEqualSlices(u8, &expected, &result);
}

comptime {
    @setEvalBranchQuota(10000);
    for (0..10000) |i| {
        _ = struct {
            const index = i;
            test {
                try runTest(index);
            }
        };
    }
}
