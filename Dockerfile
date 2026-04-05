# Stage 1: Build Nullclaw
FROM ubuntu:22.04 AS builder

# Install dependencies untuk download Zig
RUN apt-get update && apt-get install -y curl tar xz-utils git ca-certificates

# Download dan install Zig 0.15.2
RUN curl -L https://ziglang.org/download/0.15.2/zig-linux-x86_64-0.15.2.tar.xz | tar -xJ \
    && mv zig-linux-x86_64-0.15.2 /usr/local/zig \
    && ln -s /usr/local/zig/zig /usr/local/bin/zig

WORKDIR /app
COPY . .

# Build binary
RUN zig build -Doptimize=ReleaseSmall

# Stage 2: Runtime yang super ringan
FROM ubuntu:22.04

# Install ca-certificates agar bot bisa request HTTPS ke API
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy hasil build dari stage 1
COPY --from=builder /app/zig-out/bin/nullclaw .

# Jalankan bot (sesuaikan argumen jika diperlukan)
CMD ["./nullclaw"]
