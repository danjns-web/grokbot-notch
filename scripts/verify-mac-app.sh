#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_BUNDLE="${1:-$ROOT_DIR/GrokBot Notch.app}"

if [ ! -d "$APP_BUNDLE" ]; then
  echo "[error] App bundle not found: $APP_BUNDLE" >&2
  exit 1
fi

echo "[verify] codesign --verify --deep --strict"
codesign --verify --deep --strict --verbose=2 "$APP_BUNDLE"

echo "[verify] spctl -a -vvv -t exec"
spctl -a -vvv -t exec "$APP_BUNDLE"

echo "[verify] xcrun stapler validate"
xcrun stapler validate "$APP_BUNDLE"

echo "[verify] OK: $APP_BUNDLE"
