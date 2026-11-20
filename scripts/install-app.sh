#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=./common.sh
source "$(dirname "$0")/common.sh"

APP_BUNDLE="$ROOT_DIR/GrokBot Notch.app"

if [ ! -d "$APP_BUNDLE" ]; then
  echo "[error] App bundle not found: $APP_BUNDLE" >&2
  echo "Build and sign first:" >&2
  echo '  CODESIGN_IDENTITY="Developer ID Application: …" ./scripts/build-mac-app.sh' >&2
  echo "Then notarise (optional) before installing, so the stapled ticket is kept." >&2
  exit 1
fi

install_app_bundle "$APP_BUNDLE"
