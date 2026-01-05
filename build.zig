const std = @import("std");

const c_sources = &.{
    "src/calcHashAB.c",
    "src/generate_initial_buffer.c",
    "src/generate_key_material.c",
    "src/generate_buffer_from_state_mixing.c",
    "src/data/data.c",
};

const c_flags = &.{
    "-fwrapv",
    "-std=c11",
};

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Test target for test-against-data.zig
    const test_data = b.addTest(.{
        .name = "test-against-data",
        .root_module = b.createModule(.{
            .root_source_file = b.path("test-against-data.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    test_data.addCSourceFiles(.{ .files = c_sources, .flags = c_flags });
    test_data.root_module.addIncludePath(b.path("src"));

    const run_test_data = b.addRunArtifact(test_data);
    const test_data_step = b.step("test-data", "Run tests against test-data.json");
    test_data_step.dependOn(&run_test_data.step);

    // Test target for test-against-lib.zig
    const test_lib = b.addTest(.{
        .name = "test-against-lib",
        .root_module = b.createModule(.{
            .root_source_file = b.path("test-against-lib.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
    });
    test_lib.addCSourceFiles(.{ .files = c_sources, .flags = c_flags });
    test_lib.root_module.addIncludePath(b.path("src"));

    const run_test_lib = b.addRunArtifact(test_lib);
    const test_lib_step = b.step("test-lib", "Run tests against libhashab32.so");
    test_lib_step.dependOn(&run_test_lib.step);

    // Default test step runs test-against-data
    const test_step = b.step("test", "Run tests against test-data.json");
    test_step.dependOn(&run_test_data.step);

    // WASM build target
    const wasm_target = b.resolveTargetQuery(.{
        .cpu_arch = .wasm32,
        .os_tag = .freestanding,
    });

    const wasm = b.addExecutable(.{
        .name = "calcHashAB",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/wasm.zig"),
            .target = wasm_target,
            .optimize = .ReleaseSmall,
        }),
    });
    wasm.addCSourceFiles(.{ .files = c_sources, .flags = c_flags });
    wasm.root_module.addIncludePath(b.path("src"));
    wasm.entry = .disabled;
    wasm.rdynamic = true;

    const install_wasm = b.addInstallArtifact(wasm, .{
        .dest_dir = .{ .override = .prefix },
        .dest_sub_path = "calcHashAB.wasm",
    });

    const wasm_step = b.step("wasm", "Build WASM module");
    wasm_step.dependOn(&install_wasm.step);
}
