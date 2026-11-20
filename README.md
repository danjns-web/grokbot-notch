# ✦ GrokBot Notch

**A native macOS Notch companion for Desktop Grok Bot** — lives inside your MacBook's hardware notch, renders your GrokBots in their authentic flat character style, and lets you talk to any of your bots in real time with **xAI Realtime Voice Mode** or quick tap-to-type chat.

[![Platform: macOS 13+](https://img.shields.io/badge/platform-macOS%2013%2B-black?logo=apple)](https://github.com/robzilla1738/grokbot-notch)
[![Node.js: 22.5+](https://img.shields.io/badge/node-%3E%3D22.5-339933?logo=nodedotjs&logoColor=white)](https://nodejs.org)
[![License: MIT](https://img.shields.io/badge/license-MIT-violet.svg)](LICENSE)

---

## 🤖 Let Your Grok Bot Set This Up For You

Want your **Grok Bot** to install and launch this for you automatically? Just paste this into your Grok Bot chat:

```text
Set up and launch GrokBot Notch on my Mac from https://github.com/danjns-web/grokbot-notch — clone it to ~/grokbot-notch, follow AGENTS.md, set CODESIGN_IDENTITY to my Developer ID Application identity, run `npm run setup`, and confirm GrokBotNotch is running. Do not read or print the launch-auth token file.
```

*(See [`GROKBOT_SETUP.md`](GROKBOT_SETUP.md) and [`AGENTS.md`](AGENTS.md) for the autonomous agent setup guide.)*

---

## ⚡ 1-Command Terminal Setup

If you prefer to run it yourself in Terminal:

```bash
git clone https://github.com/danjns-web/grokbot-notch.git ~/grokbot-notch
cd ~/grokbot-notch
export CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
npm run setup
```

Signing requires `CODESIGN_IDENTITY` (a **Developer ID Application** identity). The build will refuse Apple Development and ad-hoc signing.

To copy an already built app into `/Applications` if that folder is writable, otherwise `~/Applications`, without sudo and without rebuilding:

```bash
npm run install:app
```

---

## ✨ Features & Design

- **Starts Collapsed in the Notch → Pops Down on `⌥Space`**
  - Tucks neatly beneath your MacBook's physical camera housing showing a mini flat mark, your active bot's name, and subtle audio wave bars.
  - Press **`⌥Space`** from any app (powered by Carbon `RegisterEventHotKey` — works globally across full-screen apps with zero Accessibility permission prompts) or click the notch to pop down the U-shaped black Notch pouch.
- **Authentic Flat GrokBot Characters**
  - Renders all **25 procedural Grok Bot shapes** (`hex`, `tablet`, `pebble`, `cloud`, `squircle`, `teardrop`, `star`, `wedge`, `blob`, etc.) in their exact flat dark-mode palette with cutout eyes, eyelid blinking, cursor gaze tracking, and state-driven animations (`idle`, `listening`, `thinking`, `streaming`, `working`).
  - Automatically syncs your live bots, pinned order, and sections from Desktop Grok Bot (`ListGrokBotAgents` + local `sand-client-persistence`).
- **Instant Bot Cycling (`←` / `→`)**
  - Whenever the Notch pouch is popped down, press **`←` Left Arrow** or **`→` Right Arrow** (or click `<` / `>`) to cycle through your GrokBots.
- **Live xAI Realtime Voice Mode (`wss://api.x.ai/v1/realtime`)**
  - Click the **Bot Character** (or press **`⌘⇧G`**) to start or end a live Voice Call with the selected GrokBot.
  - Mints a live `xai-client-secret` via `GrokBotService/MintSandVoiceCallSecret` and loads your bot's exact persona, greeting, and voice tools (`send_task`, `search_conversations`, `end_the_call`) via `GrokBotService/VoiceCallHarnessSession`.
  - Streams **24,000 Hz mono PCM16** audio over a native Swift `AVAudioEngine` + `AVAudioPlayerNode` pipeline with server VAD, instant barge-in truncation (`conversation.item.truncate`), live background task dispatching (`send_task`), and the authentic Grok Bot E5↔B5 two-tone chimes.
- **Tap Waves to Type (`||||..||l|..`)**
  - Tap the bottom audio waves (or just start typing any letter on your keyboard while the Notch is expanded) to morph the waves into a left-aligned text input. Press **`Enter`** to send a message (either directly into the active voice call or as a chat message via `SendGrokBotUserMessage`).

---

## ⌨️ Keyboard Shortcuts & Controls

| Action | Shortcut / Gesture |
| :--- | :--- |
| **Expand / Collapse Notch** | **`⌥Space`** *(Option + Space)* or click the collapsed notch |
| **Previous / Next GrokBot** | **`←` / `→`** *(Left / Right Arrows when popped down)* or click **`<` / `>`** |
| **Start / Stop Voice Call** | **Click the Bot Character** or press **`⌘⇧G`** |
| **Type a Message** | **Tap the Audio Waves** *(or start typing any letter when popped down)* → **`Enter`** |
| **Cancel Typing / Close** | **`Esc`** or click outside the Notch pouch |

---

## 🏗️ Architecture

```text
grokbot-notch/
├── macos/
│   ├── NotchApp.swift        # Native NSPanel + WKWebView hit-testing + AVAudioEngine (24kHz) + Carbon HotKeys
│   ├── Info.plist            # LSUIElement bundle metadata, localhost ATS, NSMicrophoneUsageDescription
│   └── entitlements.plist    # Audio input & network entitlements (hardened runtime)
├── public/
│   ├── index.html            # Collapsed chin bar + Expanded U-shaped Notch pouch
│   ├── styles.css            # Pure black hardware-notch geometry, concave ears & spring transitions
│   ├── app.js                # Realtime WebSocket state machine, VoiceCallHarness tools & UI controller
│   ├── motion-lab.js         # Flat Grok Bot character engine (shapes, expressions, morphs, gaze)
│   └── sounds/               # Authentic UI ticks & call chimes
├── server.mjs                # Local Node.js bridge (auth discovery, ConnectRPC proxy, transcript sync)
└── scripts/
    ├── setup.sh              # Prerequisite check, signed build & launch
    ├── build-mac-app.sh      # Compiles Swift and signs with CODESIGN_IDENTITY only
    ├── notarise-mac-app.sh   # Zip, notarytool submit, staple
    ├── verify-mac-app.sh     # codesign / spctl / stapler checks
    ├── install-app.sh        # Copy to /Applications or ~/Applications (no sudo)
    └── launch.sh             # Starts local bridge & opens GrokBot Notch.app
```

---

## 🔒 Local bridge security

The Node bridge binds to **127.0.0.1 only** and rejects requests whose `Host` is not `127.0.0.1:4789` / `localhost:4789` or whose `Origin` (when present) is not the matching loopback URL. This blocks DNS rebinding and cross-site browser access.

Each server launch gets a random **32-byte auth token** (also writable via `GROKBOT_NOTCH_AUTH_TOKEN` when the Swift app spawns the process). The token is stored at `~/Library/Application Support/GrokBot Notch/launch-auth-token` (mode `0600`) so the native app can read it. Do not print or `cat` that file.

All `/api/*` routes require `Authorization: Bearer <token>` (or `X-GrokBot-Notch-Token`), compared with a timing-safe check. The native `WKWebView` receives the token via a Swift `WKUserScript` at document start. HTML served to browsers does **not** include the token, so browser preview cannot call the API.

Confirm the bridge is up without reading the token (expect HTTP **401**):

```bash
curl -s -o /dev/null -w "%{http_code}\n" -H "Host: 127.0.0.1:4789" \
  http://127.0.0.1:4789/api/bootstrap
```

Static files are served only from `public/`, with a `path.resolve` prefix check.

Server logs from `npm start` go to `~/Library/Logs/grokbot-notch/server.log` (directory `0700`, log file `0600`).

## 🔏 Build, sign, notarise, staple

These steps are meant to be run on a Mac with a **Developer ID Application** certificate and a notarytool keychain profile. This environment cannot sign or notarise for you.

**Default bundle ID:** `uk.danjns.grokbot-notch`. **You must confirm this** in the Apple Developer portal under team `KEWEWE7JMC` (or set `BUNDLE_ID` to an identifier you already own) before a Gatekeeper-clean distribution.

Node for the menu-bar app is resolved in this order: `GROKBOT_NODE_BIN`, then `~/Library/Application Support/GrokBot Notch/node-bin` (one-line path), then `~/.local/bin/node`, Homebrew, nvm/volta/fnm. Menu-bar apps often have a minimal PATH.

```bash
# 1. Named Developer ID only (fails if unset, Apple Development, or ad-hoc)
export CODESIGN_IDENTITY="Developer ID Application: Your Name (KEWEWE7JMC)"
export BUNDLE_ID="${BUNDLE_ID:-uk.danjns.grokbot-notch}"   # confirm this id
npm run build:mac

# 2. Notarise and staple (profile name only; never paste API keys into chat)
export NOTARY_PROFILE="your-notarytool-profile-name"
npm run notarise

# 3. Verify
npm run verify:app
# same checks: codesign --verify --deep --strict
#              spctl -a -vvv -t exec
#              xcrun stapler validate

# 4. Install without sudo ( /Applications if writable, else ~/Applications )
npm run install:app
```

Create the notary profile once on the Mac, in Terminal, not in chat:

```bash
xcrun notarytool store-credentials
```

Then set `NOTARY_PROFILE` to the profile **name** you chose. The scripts never read Keychain secrets themselves.

## 📍 Finding Node

If the Notch app cannot start the bridge, point it at your binary (Dan’s Air uses `/Users/danjns/.local/bin/node`):

```bash
export GROKBOT_NODE_BIN="$HOME/.local/bin/node"
# or, for Finder / menu-bar launches:
mkdir -p "$HOME/Library/Application Support/GrokBot Notch"
printf '%s\n' "$HOME/.local/bin/node" > "$HOME/Library/Application Support/GrokBot Notch/node-bin"
```

---

## 🔧 Requirements

- **macOS 13.0+** (Apple Silicon or Intel)
- **Desktop Grok Bot** (`/Applications/Grok Bot.app`) installed and signed in
- **Node.js 22.5+** (uses Node's built-in `node:sqlite` — zero `npm install` dependencies required!)
- **Xcode Command Line Tools** (`swiftc`)

---

## 🙏 Contributors

Thanks to everyone who has helped make GrokBot Notch better:

- [@pymmog](https://github.com/pymmog): hardened the local bridge with a per-launch auth token, Host and Origin checks, no more saved Grok Bot storage key, and private log files ([#1](https://github.com/robzilla1738/grokbot-notch/pull/1))
- [@cirne](https://github.com/cirne): pinned the macOS deployment target so the app launches again ([#2](https://github.com/robzilla1738/grokbot-notch/pull/2)), and found and fixed the cross-site access hole in the local API ([#3](https://github.com/robzilla1738/grokbot-notch/pull/3))

---

## 📄 License

[MIT](LICENSE)
