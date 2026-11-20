#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=./common.sh
source "$(dirname "$0")/common.sh"

INSTALL_TO_APPS=false

for arg in "$@"; do
  case "$arg" in
    --install|-i)
      INSTALL_TO_APPS=true
      ;;
  esac
done

echo "=================================================="
echo "  ✦ GrokBot Notch — Seamless macOS Setup"
echo "=================================================="

# 1. Verify macOS
if [ "$(uname -s)" != "Darwin" ]; then
  echo "[error] GrokBot Notch requires macOS."
  exit 1
fi

# 2. Verify Swift compiler (Xcode Command Line Tools)
if ! command -v swiftc >/dev/null 2>&1; then
  echo "[error] swiftc not found."
  echo "Install Xcode Command Line Tools, then re-run this script:"
  echo "  xcode-select --install"
  echo "Or install full Xcode from the App Store / developer.apple.com."
  exit 1
fi

# 3. Verify Node.js (v22.5+ required for built-in node:sqlite)
if ! NODE_BIN="$(resolve_node_bin)"; then
  echo "[error] Node.js is required (v22.5+ for built-in node:sqlite)."
  echo "Install via Homebrew (brew install node) or put node at ~/.local/bin/node."
  echo "You can also set GROKBOT_NODE_BIN to an absolute path."
  exit 1
fi

NODE_MAJOR="$("$NODE_BIN" -p 'process.versions.node.split(".")[0]')"
if [ "$NODE_MAJOR" -lt 22 ]; then
  echo "[warn] Node.js v22+ is recommended for built-in node:sqlite (found $("$NODE_BIN" -v) at $NODE_BIN)."
else
  echo "[ok] Node.js $("$NODE_BIN" -v) at $NODE_BIN"
fi

# 4. Check for Grok Bot.app
if [ ! -d "/Applications/Grok Bot.app" ]; then
  echo "[warn] /Applications/Grok Bot.app was not found. Make sure Desktop Grok Bot is installed and signed in."
else
  echo "[ok] Found /Applications/Grok Bot.app"
fi

# 5. Build GrokBot Notch.app (requires CODESIGN_IDENTITY)
chmod +x \
  "$ROOT_DIR/scripts/build-mac-app.sh" \
  "$ROOT_DIR/scripts/launch.sh" \
  "$ROOT_DIR/scripts/notarise-mac-app.sh" \
  "$ROOT_DIR/scripts/verify-mac-app.sh"
"$ROOT_DIR/scripts/build-mac-app.sh"

# 6. Optionally copy to /Applications, or ~/Applications if that needs no admin rights
if [ "$INSTALL_TO_APPS" = true ]; then
  install_app_bundle "$ROOT_DIR/GrokBot Notch.app"
fi

# 7. Launch GrokBot Notch
"$ROOT_DIR/scripts/launch.sh"

echo ""
echo "=================================================="
echo "  ✓ GrokBot Notch is live at the top of your Mac!"
echo "  • Toggle Notch:      Option + Space (⌥Space)"
echo "  • Voice Call Toggle: Cmd + Shift + G (⌘⇧G)"
echo "  • Switch GrokBots:   Left / Right Arrows (← / →)"
echo "  • Tap Audio Waves:   Type a message to your Bot"
echo "=================================================="
