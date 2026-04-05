# Stage 1: Build Nullclaw
FROM ubuntu:22.04 AS builder

RUN apt-get update && apt-get install -y curl tar xz-utils git ca-certificates
RUN curl -L https://ziglang.org/download/0.15.2/zig-x86_64-linux-0.15.2.tar.xz | tar -xJ \
    && mv zig-x86_64-linux-0.15.2 /usr/local/zig \
    && ln -s /usr/local/zig/zig /usr/local/bin/zig

WORKDIR /app
COPY . .
RUN zig build -Doptimize=ReleaseSmall

# Stage 2: Runtime
FROM ubuntu:22.04
RUN apt-get update && apt-get install -y ca-certificates libsqlite3-0 && rm -rf /var/lib/apt/lists/*

WORKDIR /app
ENV HOME=/app

COPY --from=builder /app/zig-out/bin/nullclaw .

# Script Detektif & Pembuat Config Otomatis
RUN echo '#!/bin/sh' > /app/start.sh && \
    echo 'echo "=== DIAGNOSIS VARIABEL RAILWAY ==="' >> /app/start.sh && \
    echo 'TOKEN_TG="${NULLCLAW_TELEGRAM_BOT_TOKEN:-${NULLCLAW_TELEGRAM_TOKEN}}"' >> /app/start.sh && \
    echo 'if [ -z "$TOKEN_TG" ]; then' >> /app/start.sh && \
    echo '  echo "❌ ERROR FATAL: TOKEN TELEGRAM KOSONG! Pastikan nama variabel di tab Variables Railway sudah benar."' >> /app/start.sh && \
    echo 'else' >> /app/start.sh && \
    echo '  echo "✅ TOKEN TELEGRAM TERBACA! (Panjang: ${#TOKEN_TG} karakter)"' >> /app/start.sh && \
    echo 'fi' >> /app/start.sh && \
    echo 'mkdir -p /app/.nullclaw/workspace /app/data /app/.config/nullclaw && chmod -R 777 /app' >> /app/start.sh && \
    echo 'cat <<EOF > /app/config.json' >> /app/start.sh && \
    echo '{' >> /app/start.sh && \
    echo '  "provider": "${NULLCLAW_PROVIDER:-google}",' >> /app/start.sh && \
    echo '  "model": "${NULLCLAW_MODEL:-gemini-3.1-pro-preview}",' >> /app/start.sh && \
    echo '  "api_keys": { "${NULLCLAW_PROVIDER:-google}": "${NULLCLAW_API_KEY}" },' >> /app/start.sh && \
    echo '  "workspace": "/app/.nullclaw/workspace",' >> /app/start.sh && \
    echo '  "memory": { "driver": "sqlite", "dsn": "/app/data/nullclaw.db" },' >> /app/start.sh && \
    echo '  "channels": {' >> /app/start.sh && \
    echo '    "telegram": {' >> /app/start.sh && \
    echo '      "enabled": true,' >> /app/start.sh && \
    echo '      "token": "$TOKEN_TG",' >> /app/start.sh && \
    echo '      "allow_from": ["*"]' >> /app/start.sh && \
    echo '    }' >> /app/start.sh && \
    echo '  }' >> /app/start.sh && \
    echo '}' >> /app/start.sh && \
    echo 'EOF' >> /app/start.sh && \
    echo 'cp /app/config.json /app/.nullclaw/config.json' >> /app/start.sh && \
    echo 'cp /app/config.json /app/.config/nullclaw/config.json' >> /app/start.sh && \
    echo 'cp /app/config.json /app/nullclaw.json' >> /app/start.sh && \
    echo 'exec ./nullclaw agent' >> /app/start.sh && \
    chmod +x /app/start.sh

ENTRYPOINT ["sh", "/app/start.sh"]
