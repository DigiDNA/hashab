# HashAB

HashAB is a cryptographic hash used on the sixth- and seventh-generation iPod nano (as well as in several versions of iOS), named after its position at 0xAB in `iTunesCDB`. This hash is used to prevent non-iTunes applications from editing the database files used on iPod nano; if the hash doesn't match what's expected, iPod nano will refuse to parse the database, and iTunes will display an error message saying the iPod must be restored to factory settings.

This repository contains a C implementation of HashAB, reverse engineered from [libhashab32.so](./libhashab32.so), a 32-bit Linux shared library that appeared online sometime around late 2010.

## WebAssembly

Due to the complexity of the C code, the recommended way of integrating HashAB calculation is through the generated WebAssembly module. You can download pre-built versions of the module in the [releases](https://github.com/dstaley/hashab/releases), or build it yourself by running `zig build wasm`. The module will be located at `zig-out/calcHashAB.wasm`.

### Usage

The WebAssembly module exports four functions:

1. `getInputSha1()` - Returns the address to write a 20 byte SHA1
1. `getInputUuid()` - Returns the address to write a 8 byte UUID
1. `getOutput()` - Returns the address to read a 57 byte hash
1. `calculateHash()` - Generates a HashAB from the provided SHA1 and UUID

In addition to the four functions, the module also exports its memory, which is used to write inputs and read the output.

```ts
import wasmUrl from "./calcHashAB.wasm";

const sha1 = new Uint8Array([
  /* ... */
]);
const uuid = new Uint8Array([
  /* ... */
]);

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

const sha1Ptr = getInputSha1();
const uuidPtr = getInputUuid();
const outputPtr = getOutput();

mem.set(sha1, sha1Ptr);
mem.set(uuid, uuidPtr);

calculateHash();

const result = mem.slice(outputPtr, outputPtr + 57);
```

## Testing

There are three levels of tests in this repo:

1. A set of 100 test cases in [test-data.json](./test-data.json) that can be tested with `zig build test-data`
1. A test of the generated WebAssembly module that uses the same test cases as above that can be tested with `zig build wasm && bun test`
1. A test program that compares the result of the C implementation against the original `libhashab32.so` across 10,000 randomly generated inputs, which can be run via the included `Dockerfile` with `docker build --platform linux/386 -t hashab:latest . && docker run --rm --platform linux/386 hashab:latest`

## License

All code in this repository is made available under [The Unlicense](./LICENSE).
