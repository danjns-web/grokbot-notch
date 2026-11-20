#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_BUNDLE="$ROOT_DIR/GrokBot Notch.app"
CONTENTS_DIR="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"

# Default is Dan's reverse-DNS id. Confirm it in the Apple Developer portal
# (team KEWEWE7JMC) or override with BUNDLE_ID.
BUNDLE_ID="${BUNDLE_ID:-uk.danjns.grokbot-notch}"

if [ -z "$BUNDLE_ID" ] || [[ "$BUNDLE_ID" =~ [^A-Za-z0-9.-] ]] || [[ "$BUNDLE_ID" == *..* ]]; then
  echo "[error] BUNDLE_ID must be a reverse-DNS identifier (letters, digits, dots, hyphens)." >&2
  exit 1
fi

if [ -z "${CODESIGN_IDENTITY:-}" ]; then
  echo "[error] CODESIGN_IDENTITY is required." >&2
  echo "Set it to a Developer ID Application identity, for example:" >&2
  echo '  export CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"' >&2
  echo "List identities with: security find-identity -v -p codesigning" >&2
  echo "Ad-hoc and Apple Development identities are not accepted (they cannot be notarised)." >&2
  exit 1
fi

case "$CODESIGN_IDENTITY" in
  "Developer ID Application:"*)
    ;;
  *)
    echo "[error] CODESIGN_IDENTITY must be a Developer ID Application identity." >&2
    echo "Apple Development and ad-hoc signing are not accepted." >&2
    exit 1
    ;;
esac

echo "[build] Building GrokBot Notch.app..."
echo "[build] Bundle ID: $BUNDLE_ID"
rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR/app"

awk -v id="$BUNDLE_ID" '
  /<key>CFBundleIdentifier<\/key>/ {
    print
    getline
    print "  <string>" id "</string>"
    next
  }
  { print }
' "$ROOT_DIR/macos/Info.plist" > "$CONTENTS_DIR/Info.plist"

if [ -f "/Applications/Grok Bot.app/Contents/Resources/icon.icns" ]; then
  cp "/Applications/Grok Bot.app/Contents/Resources/icon.icns" "$RESOURCES_DIR/icon.icns"
fi

cp "$ROOT_DIR/server.mjs" "$RESOURCES_DIR/app/server.mjs"
cp "$ROOT_DIR/package.json" "$RESOURCES_DIR/app/package.json"
cp -R "$ROOT_DIR/public" "$RESOURCES_DIR/app/public"

# swiftc defaults the deployment target to the active SDK (currently macOS 28),
# which Launch Services rejects on older systems with error -10825.
ARCH="$(uname -m)"
swiftc -O \
  -target "${ARCH}-apple-macosx13.0" \
  -framework Cocoa \
  -framework WebKit \
  -framework AVFoundation \
  -framework Carbon \
  "$ROOT_DIR/macos/NotchApp.swift" \
  -o "$MACOS_DIR/GrokBotNotch"

echo "[build] Signing with Developer ID (hardened runtime, secure timestamp)..."
codesign --force --options runtime --timestamp \
  --entitlements "$ROOT_DIR/macos/entitlements.plist" \
  --sign "$CODESIGN_IDENTITY" \
  "$APP_BUNDLE"

echo "[build] Built and signed: $APP_BUNDLE"
echo "[build] Next: NOTARY_PROFILE=your-profile-name ./scripts/notarise-mac-app.sh"
