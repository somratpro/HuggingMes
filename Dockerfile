# HuggingMes - Hermes Agent Gateway for Hugging Face Spaces

ARG HERMES_AGENT_VERSION
FROM nousresearch/hermes-agent:${HERMES_AGENT_VERSION:-latest}

USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    jq \
    sudo \
    python3 \
    python3-venv \
    python3-pip \
    chromium \
    dbus \
    dbus-x11 \
    libnss3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libdrm2 \
    libgbm1 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libxkbcommon0 \
    libx11-6 \
    libxext6 \
    libxfixes3 \
    fonts-dejavu-core \
    fonts-liberation \
    fonts-noto-color-emoji \
    && (apt-get install -y --no-install-recommends libasound2 2>/dev/null \
        || apt-get install -y --no-install-recommends libasound2t64 2>/dev/null \
        || true) \
    && rm -rf /var/lib/apt/lists/* \
    && uv pip install --python /opt/hermes/.venv/bin/python --no-cache-dir \
        huggingface_hub \
        hf_transfer \
        "jupyterlab>=4.0,<5" \
        "tornado>=6.4" \
        "ipywidgets>=8.1" \
    && printf 'hermes ALL=(ALL) NOPASSWD: ALL\n' > /etc/sudoers.d/hermes \
    && chmod 0440 /etc/sudoers.d/hermes \
    && /usr/sbin/visudo -cf /etc/sudoers.d/hermes

COPY --chown=hermes:hermes start.sh /opt/huggingmes/start.sh
COPY --chown=hermes:hermes health-server.js /opt/huggingmes/health-server.js
COPY --chown=hermes:hermes hermes-sync.py /opt/huggingmes/hermes-sync.py
COPY --chown=hermes:hermes cloudflare-proxy-setup.py /opt/huggingmes/cloudflare-proxy-setup.py
COPY --chown=hermes:hermes cloudflare-keepalive-setup.py /opt/huggingmes/cloudflare-keepalive-setup.py
COPY --chown=hermes:hermes env-builder.html /opt/huggingmes/env-builder.html
COPY --chown=hermes:hermes env-builder.js /opt/huggingmes/env-builder.js

# s6 cont-init.d hook: aliases GATEWAY_TOKEN -> API_SERVER_KEY in the gateway's
# container_environment before main-hermes starts, so the gateway's API server
# (enabled via API_SERVER_ENABLED above) has the key it requires to bind 8642.
# Must stay root-owned (runs as root, writes the root-owned env dir).
COPY cont-init.d/016-huggingmes-api-server-key /etc/cont-init.d/016-huggingmes-api-server-key

RUN chmod +x \
    /opt/huggingmes/start.sh \
    /opt/huggingmes/hermes-sync.py \
    /opt/huggingmes/cloudflare-proxy-setup.py \
    /opt/huggingmes/cloudflare-keepalive-setup.py \
    /etc/cont-init.d/016-huggingmes-api-server-key

# Patch kanban migration: wrap ALTER TABLE ADD COLUMN in try/except so a
# persisted DB with the column already present doesn't crash the gateway.
# Entire block wrapped in try/except — skips silently if Hermes fixes this
# upstream or the file structure changes.
RUN python3 - <<'PY'
import sys
try:
    from pathlib import Path

    p = Path("/opt/hermes/hermes_cli/kanban_db.py")
    if not p.exists():
        print("kanban patch: file not found, skipping")
        sys.exit(0)

    src = p.read_text(encoding="utf-8", errors="replace")
    sentinel = "# huggingmes: idempotent-alter"
    if sentinel in src:
        print("kanban patch: already applied, skipping")
        sys.exit(0)

    old = (
        '    conn.execute(\n'
        '        "ALTER TABLE tasks ADD COLUMN consecutive_failures "\n'
        '        "INTEGER NOT NULL DEFAULT 0"\n'
        '    )'
    )
    new = (
        f'    try:  {sentinel}\n'
        '        conn.execute(\n'
        '            "ALTER TABLE tasks ADD COLUMN consecutive_failures "\n'
        '            "INTEGER NOT NULL DEFAULT 0"\n'
        '        )\n'
        '    except Exception:\n'
        '        pass'
    )

    if old not in src:
        print("kanban patch: pattern not found, may be fixed upstream, skipping")
        sys.exit(0)

    p.write_text(src.replace(old, new), encoding="utf-8")
    print("kanban patch: applied")
except Exception as e:
    print(f"kanban patch: error ({e}), skipping", file=sys.stderr)
PY

# hermes v0.17+ self-patches its own Python files at container startup
# (workspace/startup.sh), but ships them read-only in the image.
# Make all subdirs traversable first so find reaches every .py file; dirs
# without execute permission cause find to silently skip them.
# Use a+w (not u+w): this RUN executes as root during build, but HF Spaces
# runs the container as an arbitrary non-root UID at runtime — u+w only
# grants write to the file's owner (root), which the runtime UID isn't.
RUN find /opt/hermes -type d -exec chmod a+rwx {} + 2>/dev/null || true \
    && find /opt/hermes -name "*.py" -exec chmod a+w {} + 2>/dev/null || true

# Ensure hermes CLI is discoverable in ALL shell types (login, interactive,
# non-interactive). /etc/profile.d/ is sourced by login shells after /etc/profile
# resets PATH, so this survives even full environment resets.
RUN echo 'export PATH="/opt/hermes/.venv/bin:/opt/data/.local/bin:$PATH"' \
    > /etc/profile.d/hermes-venv.sh

# API_SERVER_* must be Docker ENV, not start.sh exports. The gateway runs as
# an independent s6-supervised service (main-hermes) that reads its environment
# from s6's container_environment — populated from PID 1's env (Docker ENV +
# runtime secrets) — NOT from start.sh's exports. The gateway enables its
# OpenAI-compatible API server (binds 127.0.0.1:8642) only when it sees
# API_SERVER_ENABLED=true (gateway/config.py). Without this the port stays
# unbound and the dashboard correctly reports "Gateway: Offline" even though
# telegram works (telegram doesn't depend on 8642). Proven by HERMES_HOME below:
# it reaches the gateway the same way. A runtime HF Space secret of the same
# name overrides these defaults.
ENV HERMES_HOME=/opt/data \
    HUGGINGMES_APP_DIR=/opt/huggingmes \
    HERMES_AGENT_VERSION=${HERMES_AGENT_VERSION} \
    PYTHONUNBUFFERED=1 \
    PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH=/usr/bin/chromium \
    API_SERVER_ENABLED=true \
    API_SERVER_HOST=127.0.0.1 \
    API_SERVER_PORT=8642

EXPOSE 7861

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s \
  CMD curl -fsS http://localhost:7861/health || exit 1

CMD ["/opt/huggingmes/start.sh"]
