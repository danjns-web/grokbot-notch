#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_BUNDLE="${1:-$ROOT_DIR/GrokBot Notch.app}"
ZIP_PATH="$ROOT_DIR/GrokBot Notch.zip"

# Profile and identity are names only. Never print, log, or read secrets.
if [ -z "${NOTARY_PROFILE:-}" ]; then
  echo "[error] NOTARY_PROFILE is required (the notarytool keychain profile name)." >&2
  echo "On your Mac, once: xcrun notarytool store-credentials" >&2
  echo "Then: export NOTARY_PROFILE=your-profile-name" >&2
  exit 1
fi

if [ ! -d "$APP_BUNDLE" ]; then
  echo "[error] App bundle not found: $APP_BUNDLE" >&2
  echo "Build and sign first:" >&2
  echo '  CODESIGN_IDENTITY="Developer ID Application: …" ./scripts/build-mac-app.sh' >&2
  exit 1
fi

echo "[notary] Zipping app bundle..."
rm -f "$ZIP_PATH"
ditto -c -k --keepParent "$APP_BUNDLE" "$ZIP_PATH"

echo "[notary] Submitting to Apple notary service..."
xcrun notarytool submit "$ZIP_PATH" --keychain-profile "$NOTARY_PROFILE" --wait

echo "[notary] Stapling ticket..."
xcrun stapler staple "$APP_BUNDLE"

echo "[notary] Verifying signed and stapled bundle..."
"$ROOT_DIR/scripts/verify-mac-app.sh" "$APP_BUNDLE"

echo "[notary] Done. Stapled app: $APP_BUNDLE"
echo "[notary] Zip left at: $ZIP_PATH (safe to delete after a successful staple)"
