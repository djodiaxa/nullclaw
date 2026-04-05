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

# Script penyembuh amnesia & pemanggil Telegram
RUN echo '#!/bin/sh' > /app/start.sh && \
    echo 'echo "=== MENYIAPKAN FOLDER & DATABASE ==="' >> /app/start.sh && \
    echo 'mkdir -p /app/.nullclaw/workspace' >> /app/start.sh && \
    echo 'chmod -R 777 /app/.nullclaw' >> /app/start.sh && \
    echo 'echo "=== MEMBUAT FILE CONFIG TELEGRAM ==="' >> /app/start.sh && \
    echo 'cat <<EOF > /app/.nullclaw/config.json' >> /app/start.sh && \
    echo '{' >> /app/start.sh && \
    echo '  "workspace": "/app/.nullclaw/workspace",' >> /app/start.sh && \
    echo '  "memory": {' >> /app/start.sh && \
    echo '    "driver": "sqlite",' >> /app/start.sh && \
    echo '    "dsn": "/app/.nullclaw/nullclaw.db"' >> /app/start.sh && \
    echo '  },' >> /app/start.sh && \
    echo '  "channels": {' >> /app/start.sh && \
    echo '    "telegram": {' >> /app/start.sh && \
    echo '      "enabled": true,' >> /app/start.sh && \
    echo '      "bot_token": "${NULLCLAW_TELEGRAM_BOT_TOKEN}",' >> /app/start.sh && \
    echo '      "allow_from": ["*"]' >> /app/start.sh && \
    echo '    }' >> /app/start.sh && \
    echo '  }' >> /app/start.sh && \
    echo '}' >> /app/start.sh && \
    echo 'EOF' >> /app/start.sh && \
    echo 'echo "=== MENYALAKAN BOT ==="' >> /app/start.sh && \
    echo 'exec ./nullclaw agent' >> /app/start.sh && \
    chmod +x /app/start.sh

CMD ["sh", "/app/start.sh"]
