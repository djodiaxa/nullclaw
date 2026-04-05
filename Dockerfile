# Stage 1: Build Nullclaw
FROM ubuntu:22.04 AS builder

# Install dependencies untuk download Zig
RUN apt-get update && apt-get install -y curl tar xz-utils git ca-certificates

# Download dan install Zig 0.15.2
RUN curl -L https://ziglang.org/download/0.15.2/zig-x86_64-linux-0.15.2.tar.xz | tar -xJ \
    && mv zig-x86_64-linux-0.15.2 /usr/local/zig \
    && ln -s /usr/local/zig/zig /usr/local/bin/zig

WORKDIR /app
COPY . .

# Build binary
RUN zig build -Doptimize=ReleaseSmall

# Stage 2: Runtime yang super ringan
FROM ubuntu:22.04

# Install ca-certificates agar bot bisa request HTTPS ke AI dan Telegram
RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Buat folder untuk database ingatan (SQLite) dan beri izin akses nulis penuh ke seluruh folder app
RUN mkdir -p data db memory && chmod -R 777 /app

# Copy hasil build biner Nullclaw dari stage 1
COPY --from=builder /app/zig-out/bin/nullclaw .

# Jalankan bot langsung dalam mode standby (agent)
CMD ["./nullclaw", "agent"]
