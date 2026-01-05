const c = @cImport({
    @cInclude("calcHashAB.h");
});

// Internal static buffers
var input_sha1: [20]u8 = undefined;
var input_uuid: [8]u8 = undefined;
var output: [57]u8 = undefined;

// Fixed random bytes value (embedded constant)
const rnd_bytes: *const [23]u8 = "ABCDEFGHIJKLMNOPQRSTUVW";

/// Get pointer to SHA1 input buffer.
/// Host should write 20 bytes to this address before calling calculateHash().
export fn getInputSha1() [*]u8 {
    return &input_sha1;
}

/// Get pointer to UUID input buffer.
/// Host should write 8 bytes to this address before calling calculateHash().
export fn getInputUuid() [*]u8 {
    return &input_uuid;
}

/// Get pointer to output buffer.
/// After calculateHash() returns, read 57 bytes from this address.
export fn getOutput() [*]u8 {
    return &output;
}

/// Calculate hash using internal buffers.
///
/// Prerequisites:
///   - Write 20 bytes to getInputSha1()
///   - Write 8 bytes to getInputUuid()
///
/// After call:
///   - Read 57 bytes from getOutput()
export fn calculateHash() void {
    c.calcHashAB(&output, &input_sha1, &input_uuid, rnd_bytes);
}
