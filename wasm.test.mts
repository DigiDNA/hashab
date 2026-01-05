import { expect, test } from "bun:test";
import wasmUrl from "./zig-out/calcHashAB.wasm";
import testData from "./test-data.json";

function hexToBytes(hex: string): Uint8Array {
  const bytes = new Uint8Array(hex.length / 2);
  for (let i = 0; i < bytes.length; i++) {
    bytes[i] = parseInt(hex.substr(i * 2, 2), 16);
  }
  return bytes;
}

function bytesToHex(bytes: Uint8Array): string {
  return Array.from(bytes)
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

const wasmBuffer = await Bun.file(wasmUrl).arrayBuffer();

const { instance } = await WebAssembly.instantiate(wasmBuffer, {});

const { getInputSha1, getInputUuid, getOutput, calculateHash, memory } =
  instance.exports as {
    getInputSha1: () => number;
    getInputUuid: () => number;
    getOutput: () => number;
    calculateHash: () => void;
    memory: WebAssembly.Memory;
  };

const mem = new Uint8Array(memory.buffer);

for (const testCase of testData) {
  test(`generates expected output for ${testCase.sha1} and ${testCase.uuid}`, async () => {
    const sha1Ptr = getInputSha1();
    const uuidPtr = getInputUuid();
    const outputPtr = getOutput();

    const sha1 = hexToBytes(testCase.sha1);
    const uuid = hexToBytes(testCase.uuid);

    mem.set(sha1, sha1Ptr);
    mem.set(uuid, uuidPtr);

    calculateHash();

    const result = mem.slice(outputPtr, outputPtr + 57);
    const resultHex = bytesToHex(result);

    expect(resultHex).toBe(testCase.target);
  });
}
