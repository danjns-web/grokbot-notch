#!/usr/bin/env bash
set -euo pipefail
umask 077

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=./common.sh
source "$(dirname "$0")/common.sh"

LOG_DIR="${HOME}/Library/Logs/grokbot-notch"
mkdir -p "$LOG_DIR"
chmod 700 "$LOG_DIR"
LOG_FILE="${LOG_DIR}/server.log"
touch "$LOG_FILE"
chmod 600 "$LOG_FILE"
APP_BUNDLE="$ROOT_DIR/GrokBot Notch.app"

if [ ! -d "$APP_BUNDLE" ]; then
  "$ROOT_DIR/scripts/build-mac-app.sh"
fi

if ! NODE_BIN="$(resolve_node_bin)"; then
  echo "[error] Node.js v22.5+ not found. Set GROKBOT_NODE_BIN to the node binary, or install Node so that ~/.local/bin/node exists." >&2
  exit 1
fi

quit_notch_app
stop_bridge_server

nohup "$NODE_BIN" "$ROOT_DIR/server.mjs" >>"$LOG_FILE" 2>&1 &
sleep 0.5

open "$APP_BUNDLE"
echo "GrokBot Notch.app is now running at the top of your screen."
echo "The local bridge binds to 127.0.0.1:4789 for the native app only (browser preview is off)."
