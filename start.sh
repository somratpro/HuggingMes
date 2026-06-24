#!/bin/bash
set -euo pipefail

umask 0077

# ════════════════════════════════════════════════════════════════
# HuggingMes — Hermes Gateway for HF Spaces
# ════════════════════════════════════════════════════════════════

# ── Startup Banner ──
APP_DIR="${HUGGINGMES_APP_DIR:-/opt/huggingmes}"
HERMES_HOME="${HERMES_HOME:-/opt/data}"
PUBLIC_PORT="${PORT:-7861}"
GATEWAY_API_PORT="${API_SERVER_PORT:-8642}"
DASHBOARD_PORT="${DASHBOARD_PORT:-9119}"
TELEGRAM_WEBHOOK_PORT="${TELEGRAM_WEBHOOK_PORT:-8765}"
SYNC_INTERVAL="${SYNC_INTERVAL:-600}"
BACKUP_DATASET="${BACKUP_DATASET_NAME:-huggingmes-backup}"
GATEWAY_HEALTH_INTERVAL="${GATEWAY_HEALTH_INTERVAL:-5}"   # seconds between health polls
GATEWAY_HEALTH_FAILURES="${GATEWAY_HEALTH_FAILURES:-3}"   # consecutive failures before restart
CF_PROXY_ENV_FILE="/tmp/huggingmes-cloudflare-proxy.env"
STARTUP_FILE="$HERMES_HOME/workspace/startup.sh"

export HERMES_HOME
export API_SERVER_ENABLED="${API_SERVER_ENABLED:-true}"
export API_SERVER_HOST="${API_SERVER_HOST:-127.0.0.1}"
export API_SERVER_PORT="$GATEWAY_API_PORT"
export GATEWAY_HEALTH_URL="${GATEWAY_HEALTH_URL:-http://127.0.0.1:${GATEWAY_API_PORT}}"
export TELEGRAM_WEBHOOK_PORT
export HERMES_GATEWAY_NO_SUPERVISE="${HERMES_GATEWAY_NO_SUPERVISE:-true}"

echo ""
echo "  ╔══════════════════════════════════════════╗"
echo "  ║        🪽 HuggingMes Hermes Gateway      ║"
echo "  ╚══════════════════════════════════════════╝"
echo ""

if [ -z "${API_SERVER_KEY:-}" ]; then
  if [ -n "${GATEWAY_TOKEN:-}" ]; then
    export API_SERVER_KEY="$GATEWAY_TOKEN"
  else
    API_SERVER_KEY="$(python3 - <<'PY'
import secrets
print(secrets.token_urlsafe(32))
PY
)"
    export API_SERVER_KEY
    echo "GATEWAY_TOKEN not set - generated an ephemeral API token for this boot."
  fi
fi

# ── Setup directories ──
mkdir -p "$HERMES_HOME"/{cron,sessions,logs,hooks,memories,skills,skins,plans,workspace,home,plugins}

# Expose hermes CLI in ~/.local/bin so login shells (terminal backend) find it.
# Base image PATH includes /opt/data/.local/bin but hermes lives in the venv.
mkdir -p "$HERMES_HOME/.local/bin"
ln -sfn /opt/hermes/.venv/bin/hermes "$HERMES_HOME/.local/bin/hermes"

# Redirect Hermes plugin dir into volume so plugins survive container restarts
if [ ! -L "${HOME}/.hermes/plugins" ]; then
  mkdir -p "${HOME}/.hermes"
  rm -rf "${HOME}/.hermes/plugins"
  ln -sfn "$HERMES_HOME/plugins" "${HOME}/.hermes/plugins"
fi

# ── Restore workspace/state from HF Dataset ──
if [ -n "${HF_TOKEN:-}" ]; then
  echo "Restoring Hermes state from HF Dataset..."
  python3 "$APP_DIR/hermes-sync.py" restore || true
else
  echo "HF_TOKEN not set - dataset persistence is disabled."
fi

CLOUDFLARE_WORKERS_TOKEN="${CLOUDFLARE_WORKERS_TOKEN:-${CLOUDFLARE_API_TOKEN:-}}"
export CLOUDFLARE_WORKERS_TOKEN
if [ -n "${CLOUDFLARE_WORKERS_TOKEN:-}" ] || [ -n "${CLOUDFLARE_PROXY_URL:-}" ]; then
  export CLOUDFLARE_PROXY_DEBUG="${CLOUDFLARE_PROXY_DEBUG:-false}"
  echo "Preparing Cloudflare Telegram proxy..."
  python3 "$APP_DIR/cloudflare-proxy-setup.py" || true
  if [ -f "$CF_PROXY_ENV_FILE" ]; then
    . "$CF_PROXY_ENV_FILE"
  fi
fi

if [ -n "${CLOUDFLARE_WORKERS_TOKEN:-}" ]; then
  echo "Preparing Cloudflare Keepalive worker..."
  python3 "$APP_DIR/cloudflare-keepalive-setup.py" || true
fi

if [ -n "${TELEGRAM_USER_IDS:-}" ] && [ -z "${TELEGRAM_ALLOWED_USERS:-}" ]; then
  export TELEGRAM_ALLOWED_USERS="$TELEGRAM_USER_IDS"
elif [ -n "${TELEGRAM_USER_ID:-}" ] && [ -z "${TELEGRAM_ALLOWED_USERS:-}" ]; then
  export TELEGRAM_ALLOWED_USERS="$TELEGRAM_USER_ID"
fi

if [ -n "${TELEGRAM_BOT_TOKEN:-}" ] && [ -n "${SPACE_HOST:-}" ] && [ -z "${TELEGRAM_WEBHOOK_URL:-}" ]; then
  if [ "${TELEGRAM_MODE:-webhook}" != "polling" ]; then
    export TELEGRAM_WEBHOOK_URL="https://${SPACE_HOST}/telegram"
  fi
fi

if [ -n "${TELEGRAM_WEBHOOK_URL:-}" ] && [ -z "${TELEGRAM_WEBHOOK_SECRET:-}" ]; then
  SECRET_FILE="$HERMES_HOME/.huggingmes-telegram-webhook-secret"
  if [ -f "$SECRET_FILE" ]; then
    export TELEGRAM_WEBHOOK_SECRET
    TELEGRAM_WEBHOOK_SECRET="$(cat "$SECRET_FILE")"
  else
    TELEGRAM_WEBHOOK_SECRET="$(python3 - <<'PY'
import secrets
print(secrets.token_hex(32))
PY
)"
    printf '%s' "$TELEGRAM_WEBHOOK_SECRET" > "$SECRET_FILE"
    chmod 600 "$SECRET_FILE"
    export TELEGRAM_WEBHOOK_SECRET
  fi
fi

MODEL_INPUT="${HERMES_MODEL:-${LLM_MODEL:-}}"
MODEL_FOR_CONFIG="$MODEL_INPUT"
PROVIDER_FOR_CONFIG="${HERMES_INFERENCE_PROVIDER:-auto}"
LLM_API_KEY="${LLM_API_KEY:-}"

if [ -n "$MODEL_INPUT" ]; then
  MODEL_PREFIX="${MODEL_INPUT%%/*}"
else
  MODEL_PREFIX=""
fi

case "$MODEL_PREFIX" in
  openrouter)
    [ -n "$LLM_API_KEY" ] && export OPENROUTER_API_KEY="${OPENROUTER_API_KEY:-$LLM_API_KEY}"
    [ "$PROVIDER_FOR_CONFIG" = "auto" ] && PROVIDER_FOR_CONFIG="openrouter"
    MODEL_FOR_CONFIG="${MODEL_INPUT#openrouter/}"
    ;;
  huggingface|hf)
    [ -n "$LLM_API_KEY" ] && export HF_TOKEN="${HF_TOKEN:-$LLM_API_KEY}"
    [ "$PROVIDER_FOR_CONFIG" = "auto" ] && PROVIDER_FOR_CONFIG="huggingface"
    MODEL_FOR_CONFIG="${MODEL_INPUT#huggingface/}"
    ;;
  vercel-ai-gateway|ai-gateway)
    [ -n "$LLM_API_KEY" ] && export AI_GATEWAY_API_KEY="${AI_GATEWAY_API_KEY:-$LLM_API_KEY}"
    [ "$PROVIDER_FOR_CONFIG" = "auto" ] && PROVIDER_FOR_CONFIG="ai-gateway"
    MODEL_FOR_CONFIG="${MODEL_INPUT#*/}"
    ;;
  anthropic)
    [ -n "$LLM_API_KEY" ] && export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY:-$LLM_API_KEY}"
    ;;
  openai|openai-codex)
    [ -n "$LLM_API_KEY" ] && export OPENAI_API_KEY="${OPENAI_API_KEY:-$LLM_API_KEY}"
    ;;
  google|gemini)
    [ -n "$LLM_API_KEY" ] && export GOOGLE_API_KEY="${GOOGLE_API_KEY:-$LLM_API_KEY}" GEMINI_API_KEY="${GEMINI_API_KEY:-$LLM_API_KEY}"
    PROVIDER_FOR_CONFIG="gemini"
    MODEL_FOR_CONFIG="${MODEL_INPUT#*/}"   # strip "google/" or "gemini/" prefix — Hermes gemini provider needs bare model name
    ;;
  deepseek)
    [ -n "$LLM_API_KEY" ] && export DEEPSEEK_API_KEY="${DEEPSEEK_API_KEY:-$LLM_API_KEY}"
    ;;
  kimi-coding|moonshot)
    [ -n "$LLM_API_KEY" ] && export KIMI_API_KEY="${KIMI_API_KEY:-$LLM_API_KEY}"
    ;;
  kimi-coding-cn|moonshot-cn|kimi-cn)
    [ -n "$LLM_API_KEY" ] && export KIMI_CN_API_KEY="${KIMI_CN_API_KEY:-$LLM_API_KEY}"
    ;;
  minimax)
    [ -n "$LLM_API_KEY" ] && export MINIMAX_API_KEY="${MINIMAX_API_KEY:-$LLM_API_KEY}"
    ;;
  minimax-cn)
    [ -n "$LLM_API_KEY" ] && export MINIMAX_CN_API_KEY="${MINIMAX_CN_API_KEY:-$LLM_API_KEY}"
    ;;
  xiaomi)
    [ -n "$LLM_API_KEY" ] && export XIAOMI_API_KEY="${XIAOMI_API_KEY:-$LLM_API_KEY}"
    ;;
  zai|z-ai|z.ai|glm)
    [ -n "$LLM_API_KEY" ] && export GLM_API_KEY="${GLM_API_KEY:-$LLM_API_KEY}"
    ;;
  arcee|arcee-ai|arceeai)
    [ -n "$LLM_API_KEY" ] && export ARCEEAI_API_KEY="${ARCEEAI_API_KEY:-$LLM_API_KEY}"
    ;;
  gmi|gmi-cloud|gmicloud)
    [ -n "$LLM_API_KEY" ] && export GMI_API_KEY="${GMI_API_KEY:-$LLM_API_KEY}"
    ;;
  alibaba)
    [ -n "$LLM_API_KEY" ] && export DASHSCOPE_API_KEY="${DASHSCOPE_API_KEY:-$LLM_API_KEY}"
    ;;
  alibaba-coding-plan|alibaba_coding)
    [ -n "$LLM_API_KEY" ] && export DASHSCOPE_API_KEY="${DASHSCOPE_API_KEY:-$LLM_API_KEY}"
    ;;
  tencent-tokenhub|tencent|tokenhub|tencentmaas)
    [ -n "$LLM_API_KEY" ] && export TOKENHUB_API_KEY="${TOKENHUB_API_KEY:-$LLM_API_KEY}"
    ;;
  nvidia)
    [ -n "$LLM_API_KEY" ] && export NVIDIA_API_KEY="${NVIDIA_API_KEY:-$LLM_API_KEY}"
    ;;
  xai|grok)
    [ -n "$LLM_API_KEY" ] && export XAI_API_KEY="${XAI_API_KEY:-$LLM_API_KEY}"
    ;;
  kilocode)
    [ -n "$LLM_API_KEY" ] && export KILOCODE_API_KEY="${KILOCODE_API_KEY:-$LLM_API_KEY}"
    ;;
  opencode-zen)
    [ -n "$LLM_API_KEY" ] && export OPENCODE_ZEN_API_KEY="${OPENCODE_ZEN_API_KEY:-$LLM_API_KEY}"
    ;;
  opencode-go)
    [ -n "$LLM_API_KEY" ] && export OPENCODE_GO_API_KEY="${OPENCODE_GO_API_KEY:-$LLM_API_KEY}"
    ;;
esac

if [ -n "${CUSTOM_BASE_URL:-}" ]; then
  PROVIDER_FOR_CONFIG="${CUSTOM_PROVIDER:-custom}"
  [ -n "$LLM_API_KEY" ] && export OPENAI_API_KEY="${OPENAI_API_KEY:-$LLM_API_KEY}"
fi

export MODEL_FOR_CONFIG PROVIDER_FOR_CONFIG
export CUSTOM_BASE_URL="${CUSTOM_BASE_URL:-}"
export CUSTOM_API_KEY="${CUSTOM_API_KEY:-${LLM_API_KEY:-}}"
export CUSTOM_MODEL_CONTEXT_LENGTH="${CUSTOM_MODEL_CONTEXT_LENGTH:-131072}"
export CUSTOM_MODEL_MAX_TOKENS="${CUSTOM_MODEL_MAX_TOKENS:-8192}"
export TELEGRAM_BASE_URL="${TELEGRAM_BASE_URL:-}"
export TELEGRAM_BASE_FILE_URL="${TELEGRAM_BASE_FILE_URL:-}"

if [ -n "${CLOUDFLARE_PROXY_URL:-}" ] && [ -z "$TELEGRAM_BASE_URL" ]; then
  CLOUDFLARE_PROXY_URL="${CLOUDFLARE_PROXY_URL%/}"
  export TELEGRAM_BASE_URL="${CLOUDFLARE_PROXY_URL}/bot"
  export TELEGRAM_BASE_FILE_URL="${CLOUDFLARE_PROXY_URL}/file/bot"
fi

# ── Pool key promotion ──
# Mirror first key from comma-separated pool vars into the singular env var.
# Hermes providers read singular vars; this lets users supply pool keys like
# ANTHROPIC_API_KEYS=key1,key2 and have them picked up automatically.
promote_first_pool_key() {
  local singular_var="$1"
  local pool_var="$2"
  local singular_val="${!singular_var:-}"
  local pool_val="${!pool_var:-}"
  [ -n "$singular_val" ] && return 0
  [ -n "$pool_val" ] || return 0
  local first
  first=$(printf '%s' "$pool_val" | tr ',' '\n' | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' | awk 'NF{print; exit}')
  [ -n "$first" ] || return 0
  export "${singular_var}=$first"
}

promote_first_pool_key "OPENROUTER_API_KEY"   "OPENROUTER_API_KEYS"
promote_first_pool_key "ANTHROPIC_API_KEY"    "ANTHROPIC_API_KEYS"
promote_first_pool_key "OPENAI_API_KEY"       "OPENAI_API_KEYS"
promote_first_pool_key "GOOGLE_API_KEY"       "GOOGLE_API_KEYS"
promote_first_pool_key "GEMINI_API_KEY"       "GEMINI_API_KEYS"
promote_first_pool_key "DEEPSEEK_API_KEY"     "DEEPSEEK_API_KEYS"
promote_first_pool_key "KIMI_API_KEY"         "KIMI_API_KEYS"
promote_first_pool_key "MINIMAX_API_KEY"      "MINIMAX_API_KEYS"
promote_first_pool_key "NVIDIA_API_KEY"       "NVIDIA_API_KEYS"
promote_first_pool_key "XAI_API_KEY"          "XAI_API_KEYS"
promote_first_pool_key "KILOCODE_API_KEY"     "KILOCODE_API_KEYS"
promote_first_pool_key "GLM_API_KEY"          "GLM_API_KEYS"
promote_first_pool_key "ARCEEAI_API_KEY"      "ARCEEAI_API_KEYS"
promote_first_pool_key "DASHSCOPE_API_KEY"    "DASHSCOPE_API_KEYS"
promote_first_pool_key "GMI_API_KEY"          "GMI_API_KEYS"
promote_first_pool_key "TOKENHUB_API_KEY"     "TOKENHUB_API_KEYS"

# ── Build config ──
python3 - <<'PY'
import os
from pathlib import Path

import yaml

home = Path(os.environ["HERMES_HOME"])
path = home / "config.yaml"
try:
    config = yaml.safe_load(path.read_text(encoding="utf-8")) or {}
except FileNotFoundError:
    config = {}

model_name = os.environ.get("MODEL_FOR_CONFIG", "").strip()
provider_name = os.environ.get("PROVIDER_FOR_CONFIG", "").strip()

if model_name:
    model = config.setdefault("model", {})
    model["default"] = model_name                          # always from env — deploy-time setting
    if provider_name and provider_name != "auto":
        model["provider"] = provider_name                  # explicit provider (openrouter, huggingface, custom…)
    else:
        model.pop("provider", None)                        # let Hermes infer from model-name prefix
else:
    model = config.get("model", {})
    print("No LLM_MODEL/HERMES_MODEL set; leaving Hermes model config unchanged.")

custom_base = os.environ.get("CUSTOM_BASE_URL", "").strip()
if custom_base and model_name:
    model.setdefault("base_url", custom_base.rstrip("/"))
    if os.environ.get("CUSTOM_API_KEY"):
        model.setdefault("api_key", os.environ["CUSTOM_API_KEY"])
    try:
        model.setdefault("context_length", int(os.environ.get("CUSTOM_MODEL_CONTEXT_LENGTH", "131072")))
        model.setdefault("max_tokens", int(os.environ.get("CUSTOM_MODEL_MAX_TOKENS", "8192")))
    except ValueError:
        pass

config.setdefault("terminal", {}).setdefault("cwd", os.environ.get("MESSAGING_CWD", str(home / "workspace")))
config.setdefault("compression", {}).setdefault("enabled", True)
config.setdefault("display", {}).setdefault("background_process_notifications", os.environ.get("HERMES_BACKGROUND_NOTIFICATIONS", "result"))
config.setdefault("security", {}).setdefault("redact_secrets", True)

platforms = config.setdefault("platforms", {})

if os.environ.get("TELEGRAM_BOT_TOKEN"):
    telegram = platforms.setdefault("telegram", {})
    telegram.setdefault("enabled", True)
    extra = telegram.setdefault("extra", {})
    if os.environ.get("TELEGRAM_BASE_URL"):
        extra.setdefault("base_url", os.environ["TELEGRAM_BASE_URL"])
        extra.setdefault("base_file_url", os.environ.get("TELEGRAM_BASE_FILE_URL") or os.environ["TELEGRAM_BASE_URL"])
    if os.environ.get("TELEGRAM_ALLOWED_USERS"):
        config.setdefault("telegram", {}).setdefault("allow_from", [
            item.strip()
            for item in os.environ["TELEGRAM_ALLOWED_USERS"].split(",")
            if item.strip()
        ])

path.write_text(yaml.safe_dump(config, sort_keys=False), encoding="utf-8")
path.chmod(0o600)
PY

# ── Startup Summary ──
HERMES_RUNTIME_VERSION="$(/opt/hermes/.venv/bin/hermes --version 2>/dev/null | awk '{print $NF; exit}' || true)"
echo ""
if [ -n "${HERMES_RUNTIME_VERSION:-}" ]; then
  echo "Version   : ${HERMES_RUNTIME_VERSION}"
fi
echo "Model     : ${MODEL_FOR_CONFIG:-unset}"
echo "Provider  : ${PROVIDER_FOR_CONFIG:-unset}"
if [ -n "${TELEGRAM_BOT_TOKEN:-}" ]; then
  if [ -n "${TELEGRAM_WEBHOOK_URL:-}" ]; then
    echo "Telegram  : webhook"
  else
    echo "Telegram  : polling"
  fi
else
  echo "Telegram  : not configured"
fi
if [ -n "${HF_TOKEN:-}" ]; then
  echo "Backup    : ${BACKUP_DATASET} (every ${SYNC_INTERVAL:-600}s)"
else
  echo "Backup    : disabled"
fi
if [ -n "${CLOUDFLARE_PROXY_URL:-}" ]; then
  echo "Proxy     : ${CLOUDFLARE_PROXY_URL}"
fi
echo "Routes    : /app/ (Hermes UI), /terminal/ (JupyterLab)"
echo "Dashboard : http://127.0.0.1:${DASHBOARD_PORT}"
echo "Gateway   : http://127.0.0.1:${GATEWAY_API_PORT}"
echo ""

# Wait for a TCP port to stop being bound (pure bash, no lsof/fuser).
wait_for_port_free() {
  local port="$1" timeout="${2:-30}" i
  for ((i=0; i<timeout; i++)); do
    (echo > "/dev/tcp/127.0.0.1/$port") 2>/dev/null || return 0
    sleep 1
  done
  echo "Warning: port $port still bound after ${timeout}s; proceeding anyway." >&2
  return 0
}

# ── JupyterLab terminal (on by default when GATEWAY_TOKEN is set) ──
JUPYTER_PID=""
start_jupyter() {
  if [ "${DEV_MODE:-true}" = "false" ]; then
    echo "JupyterLab disabled (DEV_MODE=false)."
    return 0
  fi
  # Guard: skip if already running
  if [ -n "${JUPYTER_PID:-}" ] && kill -0 "$JUPYTER_PID" 2>/dev/null; then
    return 0
  fi
  local token="${JUPYTER_TOKEN:-${API_SERVER_KEY:-}}"
  if [ -z "$token" ]; then
    echo "WARNING: No GATEWAY_TOKEN or JUPYTER_TOKEN set — JupyterLab skipped (terminal would be unauthenticated)." >&2
    return 0
  fi
  export JUPYTER_TOKEN="$token"
  local VENV_PYTHON="/opt/hermes/.venv/bin/python"
  if ! "$VENV_PYTHON" -c "import jupyterlab" >/dev/null 2>&1; then
    echo "WARNING: jupyterlab not installed in venv; skipping terminal." >&2
    return 0
  fi
  local root_dir="${JUPYTER_ROOT_DIR:-$HERMES_HOME/workspace}"
  mkdir -p "$root_dir"
  ln -sfn "$HERMES_HOME" "$root_dir/HuggingMes" 2>/dev/null || true
  echo "Starting JupyterLab terminal on port 8888 (root: $root_dir)"
  "$VENV_PYTHON" -m jupyterlab \
    --ip 127.0.0.1 \
    --port 8888 \
    --no-browser \
    --IdentityProvider.token="$JUPYTER_TOKEN" \
    --ServerApp.base_url=/terminal/ \
    --ServerApp.terminals_enabled=True \
    --ServerApp.terminado_settings='{"shell_command":["/bin/bash","-i"]}' \
    --ServerApp.allow_origin='*' \
    --ServerApp.allow_remote_access=True \
    --ServerApp.trust_xheaders=True \
    --ServerApp.tornado_settings="{'headers': {'Content-Security-Policy': 'frame-ancestors *'}}" \
    --IdentityProvider.cookie_options="{'SameSite': 'None', 'Secure': True}" \
    --ServerApp.disable_check_xsrf=True \
    --LabApp.news_url=None \
    --LabApp.check_for_updates_class=jupyterlab.NeverCheckForUpdate \
    --ServerApp.log_level=WARN \
    --ServerApp.root_dir="$root_dir" \
    >> "$HERMES_HOME/logs/jupyter.log" 2>&1 &
  JUPYTER_PID=$!
  export JUPYTER_PID
  echo "JupyterLab started (PID: $JUPYTER_PID)"
}

# ── Trap SIGTERM for graceful shutdown ──
SYNC_LOOP_PID=""
DASHBOARD_PID=""
SHUTTING_DOWN=""
graceful_shutdown() {
  SHUTTING_DOWN=1
  echo "Shutting down HuggingMes..."
  if [ -n "${HF_TOKEN:-}" ]; then
    python3 "$APP_DIR/hermes-sync.py" sync-once || echo "Warning: shutdown sync failed."
  fi
  # Stop gateway via CLI so hermes sets gateway_state=stopped.
  # This prevents 02-reconcile-profiles from auto-starting it on the next container boot.
  timeout 5 hermes gateway stop 2>/dev/null || true
  for pid in "${SYNC_LOOP_PID:-}" "${DASHBOARD_PID:-}" "${JUPYTER_PID:-}"; do
    [ -n "$pid" ] && kill -TERM "$pid" 2>/dev/null || true
  done
  local deadline=$((SECONDS + 10))
  while [[ -n $(jobs -p 2>/dev/null) ]]; do
    [ "$SECONDS" -ge "$deadline" ] && break
    sleep 1
  done
  kill -KILL $(jobs -p 2>/dev/null) 2>/dev/null || true
  exit 0
}
trap graceful_shutdown SIGTERM SIGINT

# ── Shell capture wrappers ──
# Written to ~/.bashrc so terminal installs are recorded in workspace/startup.sh
# and replayed on next boot — packages survive Space restarts.
if [ ! -f "$STARTUP_FILE" ]; then
  touch "$STARTUP_FILE"
  chmod +x "$STARTUP_FILE"
  echo "Created workspace/startup.sh"
fi
cat > "$HOME/.bashrc" << 'BASHRC'
export PATH="/opt/hermes/.venv/bin:/opt/data/.local/bin:$PATH"
export DEBIAN_FRONTEND="${DEBIAN_FRONTEND:-noninteractive}"
if [ -z "${PS1:-}" ] || [ "$PS1" = "$ " ]; then
  export PS1="\u@\h:\w\$ "
fi

HERMES_HOME="${HERMES_HOME:-/opt/data}"
STARTUP_FILE="$HERMES_HOME/workspace/startup.sh"

_hm_append() {
  [ "${HUGGINGMES_CAPTURE_DISABLE:-0}" = "1" ] && return 0
  local line="$*"
  mkdir -p "$(dirname "$STARTUP_FILE")"
  touch "$STARTUP_FILE"
  chmod +x "$STARTUP_FILE" 2>/dev/null || true
  grep -qxF "$line" "$STARTUP_FILE" 2>/dev/null || echo "$line" >> "$STARTUP_FILE"
}
_hm_quote_args() {
  local quoted=()
  local arg
  for arg in "$@"; do
    printf -v arg '%q' "$arg"
    quoted+=("$arg")
  done
  printf '%s' "${quoted[*]}"
}
_hm_append_cmd() {
  local cmd="$1"
  shift
  local args
  args=$(_hm_quote_args "$@")
  if [ -n "$args" ]; then
    _hm_append "$cmd $args"
  else
    _hm_append "$cmd"
  fi
}
_hm_args_without_flags() {
  local out=()
  for arg in "$@"; do
    case "$arg" in
      ''|-|--*|-*) ;;
      *) out+=("$arg") ;;
    esac
  done
  printf '%s\n' "${out[@]}"
}
_hm_has_install_targets() {
  local item
  while IFS= read -r item; do
    [ -n "$item" ] && return 0
  done <<EOF
$(_hm_args_without_flags "$@")
EOF
  return 1
}
_hm_has_arg() {
  local needle="$1"
  shift
  for arg in "$@"; do
    [ "$arg" = "$needle" ] && return 0
  done
  return 1
}
_hm_can_sudo_apt() {
  command -v sudo >/dev/null 2>&1 && sudo -n apt-get --version >/dev/null 2>&1
}
_hm_apt_install() {
  if [ "$(id -u)" -eq 0 ]; then
    command apt-get update && command apt-get install -y "$@"
  elif _hm_can_sudo_apt; then
    sudo apt-get update && sudo apt-get install -y "$@"
  else
    echo "Error: apt install needs root." >&2
    return 1
  fi
}
apt-get() {
  case "${1:-}" in
    install)
      shift
      _hm_apt_install "$@"
      local rc=$?
      if [ $rc -eq 0 ]; then
        _hm_has_install_targets "$@" && _hm_append_cmd "sudo apt-get update && sudo apt-get install -y" "$@"
      fi
      return $rc
      ;;
    update)
      if [ "$(id -u)" -eq 0 ]; then command apt-get "$@"
      elif _hm_can_sudo_apt; then sudo apt-get "$@"
      else command apt-get "$@"; fi
      return $?
      ;;
    *) command apt-get "$@"; return $? ;;
  esac
}
apt() {
  case "${1:-}" in
    install)
      shift
      _hm_apt_install "$@"
      local rc=$?
      if [ $rc -eq 0 ]; then
        _hm_has_install_targets "$@" && _hm_append_cmd "sudo apt-get update && sudo apt-get install -y" "$@"
      fi
      return $rc
      ;;
    update)
      if [ "$(id -u)" -eq 0 ]; then command apt "$@"
      elif _hm_can_sudo_apt; then sudo apt "$@"
      else command apt "$@"; fi
      return $?
      ;;
    *) command apt "$@"; return $? ;;
  esac
}
pip() {
  command pip "$@"
  local rc=$?
  if [ $rc -eq 0 ] && [ "${1:-}" = "install" ] \
      && ! _hm_has_arg -r "${@:2}" && ! _hm_has_arg --requirement "${@:2}" \
      && _hm_has_install_targets "${@:2}"; then
    _hm_append_cmd "pip install" "${@:2}"
  fi
  return $rc
}
pip3() {
  command pip3 "$@"
  local rc=$?
  if [ $rc -eq 0 ] && [ "${1:-}" = "install" ] \
      && ! _hm_has_arg -r "${@:2}" && ! _hm_has_arg --requirement "${@:2}" \
      && _hm_has_install_targets "${@:2}"; then
    _hm_append_cmd "pip install" "${@:2}"
  fi
  return $rc
}
uv() {
  command uv "$@"
  local rc=$?
  if [ $rc -eq 0 ] && [ "${1:-}" = "pip" ] && [ "${2:-}" = "install" ] \
      && ! _hm_has_arg -r "${@:3}" && ! _hm_has_arg --requirements "${@:3}" \
      && _hm_has_install_targets "${@:3}"; then
    _hm_append_cmd "uv pip install" "${@:3}"
  fi
  return $rc
}
npm() {
  command npm "$@"
  local rc=$?
  if [ $rc -eq 0 ] && { [ "${1:-}" = "install" ] || [ "${1:-}" = "i" ]; } && { [ "${2:-}" = "-g" ] || [ "${2:-}" = "--global" ]; } && _hm_has_install_targets "${@:3}"; then
    _hm_append_cmd "npm install -g" "${@:3}"
  fi
  return $rc
}
hermes() {
  command hermes "$@"
  local rc=$?
  if [ $rc -eq 0 ] && [ "${1:-}" = "plugins" ] && [ "${2:-}" = "install" ] && _hm_has_install_targets "${@:3}"; then
    _hm_append_cmd "hermes plugins install" "${@:3}"
  fi
  return $rc
}
BASHRC
cat > "$HOME/.profile" << 'PROFILE'
[ -n "${BASH_VERSION:-}" ] && [ -f ~/.bashrc ] && . ~/.bashrc
PROFILE
echo "Shell capture wrappers ready."

# ── Optional package installs from HF Variables/Secrets ──
HM_STARTUP_FAILURES=0

if [ -n "${HUGGINGMES_APT_PACKAGES:-}" ]; then
  echo "Installing apt packages from HUGGINGMES_APT_PACKAGES..."
  read -r -a HM_APT_PACKAGES <<< "$HUGGINGMES_APT_PACKAGES"
  if command -v sudo >/dev/null 2>&1; then
    if sudo apt-get update && sudo apt-get install -y "${HM_APT_PACKAGES[@]}"; then
      echo "HUGGINGMES_APT_PACKAGES install complete."
    else
      HM_STARTUP_FAILURES=$((HM_STARTUP_FAILURES + 1))
      echo "ERROR: HUGGINGMES_APT_PACKAGES install failed: ${HUGGINGMES_APT_PACKAGES}" >&2
    fi
  elif [ "$(id -u)" -eq 0 ]; then
    if apt-get update && apt-get install -y "${HM_APT_PACKAGES[@]}"; then
      echo "HUGGINGMES_APT_PACKAGES install complete."
    else
      HM_STARTUP_FAILURES=$((HM_STARTUP_FAILURES + 1))
      echo "ERROR: HUGGINGMES_APT_PACKAGES install failed: ${HUGGINGMES_APT_PACKAGES}" >&2
    fi
  else
    HM_STARTUP_FAILURES=$((HM_STARTUP_FAILURES + 1))
    echo "ERROR: root/sudo unavailable; HUGGINGMES_APT_PACKAGES skipped" >&2
  fi
fi

if [ -n "${HUGGINGMES_PIP_PACKAGES:-}" ]; then
  echo "Installing Python packages from HUGGINGMES_PIP_PACKAGES..."
  read -r -a HM_PIP_PACKAGES <<< "$HUGGINGMES_PIP_PACKAGES"
  if /opt/hermes/.venv/bin/pip install "${HM_PIP_PACKAGES[@]}"; then
    echo "HUGGINGMES_PIP_PACKAGES install complete."
  else
    HM_STARTUP_FAILURES=$((HM_STARTUP_FAILURES + 1))
    echo "ERROR: HUGGINGMES_PIP_PACKAGES install failed: ${HUGGINGMES_PIP_PACKAGES}" >&2
  fi
fi

if [ -n "${HUGGINGMES_NPM_PACKAGES:-}" ]; then
  echo "Installing npm packages from HUGGINGMES_NPM_PACKAGES..."
  read -r -a HM_NPM_PACKAGES <<< "$HUGGINGMES_NPM_PACKAGES"
  if npm install -g "${HM_NPM_PACKAGES[@]}"; then
    echo "HUGGINGMES_NPM_PACKAGES install complete."
  else
    HM_STARTUP_FAILURES=$((HM_STARTUP_FAILURES + 1))
    echo "ERROR: HUGGINGMES_NPM_PACKAGES install failed: ${HUGGINGMES_NPM_PACKAGES}" >&2
  fi
fi

# ── Arbitrary startup script (HUGGINGMES_RUN) ──
# Supports plain bash or base64-encoded scripts (prefix with base64: or b64:).
# Example: HUGGINGMES_RUN="pip install pandas && npm install -g typescript"
# Example: HUGGINGMES_RUN="base64:$(base64 -w0 setup.sh)"
hm_run_startup_auto() {
  local payload="$1"
  [ -n "$payload" ] || return 0
  local script_file
  script_file=$(mktemp "/tmp/huggingmes-startup.XXXXXX.sh")
  {
    echo 'export HUGGINGMES_CAPTURE_DISABLE=1'
    echo '[ -f ~/.bashrc ] && . ~/.bashrc'
    if [[ "$payload" == base64:* ]] || [[ "$payload" == b64:* ]]; then
      printf '%s' "${payload#*:}" | base64 -d
    else
      printf '%s\n' "$payload"
    fi
  } > "$script_file"
  chmod 700 "$script_file"
  echo "[startup:HUGGINGMES_RUN] running script"
  set +e
  bash "$script_file"
  local rc=$?
  set -e
  rm -f "$script_file"
  if [ $rc -eq 0 ]; then
    echo "[startup:HUGGINGMES_RUN] ok"
  else
    HM_STARTUP_FAILURES=$((HM_STARTUP_FAILURES + 1))
    echo "ERROR: HUGGINGMES_RUN script failed (exit ${rc})" >&2
  fi
}

if [ -n "${HUGGINGMES_RUN:-}" ]; then
  hm_run_startup_auto "$HUGGINGMES_RUN"
fi

# ── Ensure hermes Python files are writable ──
# hermes v0.17+ self-patches its own .py files inside workspace/startup.sh.
# The files ship read-only in the Docker image; make them writable now so the
# patcher can succeed. Must run after the HF Dataset restore (which runs above)
# in case the restore ever touches /opt/hermes paths via symlinks.
# First make directories traversable — find silently skips dirs without the
# execute bit (errors eaten by 2>/dev/null), so .py files inside them are never
# reached and remain read-only.
# Use a+w (not u+w): these files are owned by root from the Docker build, but
# HF Spaces runs the container as an arbitrary non-root UID at runtime — u+w
# only grants write to the owner (root), which the runtime UID isn't.
find /opt/hermes -type d -exec chmod a+rwx {} + 2>/dev/null || true
find /opt/hermes -name "*.py" -exec chmod a+w {} + 2>/dev/null || true

# ── Run workspace startup script ──
# Replays install commands recorded by the shell wrappers from previous sessions.
if [ -s "$STARTUP_FILE" ]; then
  echo "Running workspace/startup.sh..."
  set +e
  HUGGINGMES_CAPTURE_DISABLE=1 bash -l "$STARTUP_FILE"
  set -e
  echo "Workspace startup script complete."
fi

if [ "$HM_STARTUP_FAILURES" -gt 0 ]; then
  echo "Warning: ${HM_STARTUP_FAILURES} startup step(s) failed. Check logs above." >&2
fi

# ── Start background services ──
node "$APP_DIR/health-server.js" &
HEALTH_PID=$!

if [ -n "${WEBHOOK_URL:-}" ]; then
  python3 - <<'PY' >/dev/null 2>&1 &
import json, os, urllib.request
body = json.dumps({
    "event": "restart",
    "status": "success",
    "message": "HuggingMes Hermes gateway has started.",
    "model": os.environ.get("MODEL_FOR_CONFIG", ""),
}).encode()
req = urllib.request.Request(os.environ["WEBHOOK_URL"], data=body, method="POST", headers={"Content-Type": "application/json"})
urllib.request.urlopen(req, timeout=10).read()
PY
fi

# ── Launch dashboard once (restarts if it dies) ──
start_dashboard_once() {
  if [ -n "${DASHBOARD_PID:-}" ] && kill -0 "$DASHBOARD_PID" 2>/dev/null; then
    return 0
  fi
  echo "Launching Hermes dashboard on 127.0.0.1:${DASHBOARD_PORT}..."
  (hermes dashboard --host 127.0.0.1 --insecure 2>&1 | tee -a "$HERMES_HOME/logs/dashboard.log") &
  DASHBOARD_PID=$!
}

# ── Start sync loop once — survives gateway restarts ──
start_background_sync_once() {
  [ -n "${HF_TOKEN:-}" ] || return 0
  if [ -n "${SYNC_LOOP_PID:-}" ] && kill -0 "$SYNC_LOOP_PID" 2>/dev/null; then
    return 0
  fi
  python3 -u "$APP_DIR/hermes-sync.py" loop &
  SYNC_LOOP_PID=$!
}

start_dashboard_once
start_jupyter

# ── Gateway restart loop ──
GATEWAY_RESTART_DELAY="${GATEWAY_RESTART_DELAY:-5}"
GATEWAY_MAX_RESTARTS="${GATEWAY_MAX_RESTARTS:-0}"
GATEWAY_RESTART_COUNT=0
GATEWAY_READY_TIMEOUT="${GATEWAY_READY_TIMEOUT:-120}"

while true; do
  # Monitor health-server — restart if it died unexpectedly
  if [ -n "${HEALTH_PID:-}" ] && ! kill -0 "$HEALTH_PID" 2>/dev/null; then
    echo "Warning: health-server exited (PID $HEALTH_PID dead); restarting..."
    node "$APP_DIR/health-server.js" &
    HEALTH_PID=$!
    echo "Health server restarted (PID: $HEALTH_PID)"
  fi

  # Monitor Hermes dashboard — restart if it died unexpectedly
  if [ -n "${DASHBOARD_PID:-}" ] && ! kill -0 "$DASHBOARD_PID" 2>/dev/null; then
    echo "Warning: Hermes dashboard exited; restarting..."
    start_dashboard_once
  fi

  # Monitor JupyterLab — restart if it died unexpectedly
  if [ "${DEV_MODE:-true}" != "false" ] && [ -n "${JUPYTER_PID:-}" ] && ! kill -0 "$JUPYTER_PID" 2>/dev/null; then
    echo "Warning: JupyterLab exited (PID $JUPYTER_PID dead); restarting..."
    unset JUPYTER_PID
    start_jupyter
  fi

  [ -n "${SHUTTING_DOWN:-}" ] && break

  # ── Launch or attach ──
  # `hermes gateway run` exits immediately after handing off to s6-supervise.
  # Use `hermes gateway restart` on subsequent iterations — `run` is refused when already supervised.
  if ! (echo > "/dev/tcp/127.0.0.1/${GATEWAY_API_PORT}") 2>/dev/null; then
    if [ "$GATEWAY_RESTART_COUNT" -eq 0 ]; then
      echo "Launching Hermes gateway..."
      wait_for_port_free "$GATEWAY_API_PORT"
      hermes gateway run >> "$HERMES_HOME/logs/gateway.log" 2>&1 || true
    else
      echo "Restarting Hermes gateway (attempt ${GATEWAY_RESTART_COUNT})..."
      hermes gateway restart >> "$HERMES_HOME/logs/gateway.log" 2>&1 || true
    fi
  fi

  # ── Wait for readiness ──
  ready=false
  for ((i=0; i<GATEWAY_READY_TIMEOUT; i++)); do
    [ -n "${SHUTTING_DOWN:-}" ] && break
    if (echo > "/dev/tcp/127.0.0.1/${GATEWAY_API_PORT}") 2>/dev/null; then
      ready=true; break
    fi
    sleep 1
  done

  if [ "$ready" != "true" ]; then
    [ -n "${SHUTTING_DOWN:-}" ] && exit 0
    echo ""
    echo "Hermes gateway failed to expose the API health port. Last 40 log lines:"
    echo "----------------------------------------"
    tail -40 "$HERMES_HOME/logs/gateway.log" || true
    exit 1
  fi

  start_background_sync_once

  # ── Monitor via health endpoint ──
  # GATEWAY_PID is not useful: the registration wrapper exits immediately after s6 hand-off.
  GATEWAY_FAIL_COUNT=0
  while true; do
    [ -n "${SHUTTING_DOWN:-}" ] && break 2
    sleep "${GATEWAY_HEALTH_INTERVAL}"
    if (echo > "/dev/tcp/127.0.0.1/${GATEWAY_API_PORT}") 2>/dev/null; then
      GATEWAY_FAIL_COUNT=0
    else
      GATEWAY_FAIL_COUNT=$((GATEWAY_FAIL_COUNT + 1))
      echo "Gateway health miss ${GATEWAY_FAIL_COUNT}/${GATEWAY_HEALTH_FAILURES}..."
      [ "$GATEWAY_FAIL_COUNT" -ge "$GATEWAY_HEALTH_FAILURES" ] && break
    fi
  done

  # Sync state before restart
  if [ -n "${HF_TOKEN:-}" ]; then
    echo "Gateway exited — syncing state before restart..."
    python3 "$APP_DIR/hermes-sync.py" sync-once || echo "Warning: sync failed."
  fi

  GATEWAY_RESTART_COUNT=$((GATEWAY_RESTART_COUNT + 1))
  if [ "$GATEWAY_MAX_RESTARTS" != "0" ] && [ "$GATEWAY_RESTART_COUNT" -ge "$GATEWAY_MAX_RESTARTS" ]; then
    echo "Gateway exited; restart limit (${GATEWAY_MAX_RESTARTS}) reached."
    exit 1
  fi

  echo "Gateway exited; restarting in ${GATEWAY_RESTART_DELAY}s..."
  sleep "$GATEWAY_RESTART_DELAY"
done
