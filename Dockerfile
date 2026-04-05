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

# Install sertifikat HTTPS dan library inti SQLite
RUN apt-get update && apt-get install -y ca-certificates libsqlite3-0 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# PAKSA Nullclaw untuk menyimpan data di dalam folder /app ini (jangan ke folder sistem)
ENV XDG_DATA_HOME=/app/data
ENV XDG_CONFIG_HOME=/app/config
ENV XDG_CACHE_HOME=/app/cache
ENV HOME=/app

# Buat semua variasi folder yang mungkin dicari oleh Nullclaw, lalu buka gemboknya (chmod 777)
RUN mkdir -p /app/data/nullclaw /app/config /app/cache /app/.local/share/nullclaw && chmod -R 777 /app

# Copy hasil build dari stage 1
COPY --from=builder /app/zig-out/bin/nullclaw .

# Jalankan bot
CMD ["./nullclaw", "agent"]
