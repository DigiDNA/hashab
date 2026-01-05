FROM i386/debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    wget \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Download and install Zig 0.15.2 for x86 Linux
RUN wget -q https://ziglang.org/download/0.15.2/zig-x86-linux-0.15.2.tar.xz \
    && tar -xf zig-x86-linux-0.15.2.tar.xz \
    && mv zig-x86-linux-0.15.2 /opt/zig \
    && rm zig-x86-linux-0.15.2.tar.xz

ENV PATH="/opt/zig:${PATH}"

WORKDIR /app

COPY libhashab32.so ./
COPY test-against-lib.zig ./
COPY build.zig ./
COPY src/ ./src/

CMD ["zig", "build", "test-lib", "--summary", "all"]
