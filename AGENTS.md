# Autonomous Setup Instructions for Grok Bot & AI Agents

If a user asked you (their **Grok Bot**, Cursor agent, Claude Code, or Codex) to set up **GrokBot Notch** on their Mac, execute the following steps end-to-end without asking unnecessary questions.

## 1. Prerequisites Check

Run a quick check to ensure the Mac has:
- **macOS 13+** (`uname -s` == `Darwin`)
- **Xcode Command Line Tools (`swiftc`)**: verify with `swiftc --version`. If it is missing, print `xcode-select --install` and stop; do not run that command yourself.
- **Node.js v22.5+** (required for built-in `node:sqlite`): look at `GROKBOT_NODE_BIN`, then `~/.local/bin/node`, Homebrew, nvm/fnm/volta, then `node -v`. Menu-bar apps have a minimal PATH, so `~/.local/bin/node` matters even when Terminal can see `node`.
- **Desktop Grok Bot (`/Applications/Grok Bot.app`)**: verify the user has Desktop Grok Bot installed and signed in.
- **Developer ID Application certificate**: signing requires `CODESIGN_IDENTITY` set to a `Developer ID Application: …` identity. Do not fall back to Apple Development or ad-hoc signing. List names only with `security find-identity -v -p codesigning`. Never print Keychain secrets or certificates.
- **Notary profile** (only when notarising): a keychain profile name in `NOTARY_PROFILE`. If it is missing, tell the user to run `xcrun notarytool store-credentials` themselves and type credentials into that window, not into chat.

## 2. Clone & Build

If you are not already inside the repository directory, clone it and run the automated setup script:

```bash
git clone https://github.com/danjns-web/grokbot-notch.git ~/grokbot-notch
cd ~/grokbot-notch
export CODESIGN_IDENTITY="Developer ID Application: …"
export BUNDLE_ID="${BUNDLE_ID:-uk.danjns.grokbot-notch}"
npm run setup
```

`BUNDLE_ID` defaults to `uk.danjns.grokbot-notch`. The owner must confirm that identifier in the Apple Developer portal (team `KEWEWE7JMC`) before treating a signed build as final.

To copy an **already built** app into `/Applications` if writable, otherwise `~/Applications`, without sudo and without rebuilding (keeps a stapled notary ticket):

```bash
npm run install:app
```

To notarise and staple after a signed build:

```bash
export NOTARY_PROFILE="your-notarytool-profile-name"
npm run notarise
npm run verify:app
```

Do not read, log, or print the notary profile contents, API keys, or the launch-auth token file.

## 3. Verify It Is Running

1. Confirm the native process is running:
   ```bash
   pgrep -x GrokBotNotch
   ```
2. Confirm the loopback bridge rejects unauthenticated API calls (expect HTTP 401). Do **not** `cat` the launch token file:
   ```bash
   curl -s -o /dev/null -w "%{http_code}\n" -H "Host: 127.0.0.1:4789" \
     http://127.0.0.1:4789/api/bootstrap
   ```
3. The Notch web UI is for the native `WKWebView` only. Browser preview is off; the bearer token is injected by the app via `WKUserScript`, not via HTML served to arbitrary browsers.

## 4. Tell the User How to Use It

Once running, let the user know:
- **`⌥Space` (Option + Space)** expands or collapses the GrokBot Notch pouch from any app.
- **`←` / `→` (Left / Right Arrow keys)** when popped down cycles through their GrokBots.
- **Click the Bot Character** (or press **`⌘⇧G`**) to start or end a live **Voice Mode** call with the selected GrokBot.
- **Tap the Audio Waves** (or just start typing while expanded) to send a quick text message to the selected GrokBot.
- First launch may show a **microphone** prompt and a **Keychain** prompt for “Grok Bot Safe Storage”. Those are expected.
