# Contributing to GrokBot Notch

Contributions, bug reports, and pull requests are welcome!

## Project Structure

- `macos/NotchApp.swift` — Native macOS AppKit + WebKit + AVAudioEngine + Carbon global hotkeys (`⌥Space`, `⌘⇧G`, `←`, `→`, `Esc`).
- `server.mjs` — Zero-dependency Node.js bridge server (`node:http`, `node:sqlite`, `node:crypto`) that reads local Grok Bot / Cursor authentication and roster state and proxies `GrokBotService` ConnectRPC calls (`ListGrokBotAgents`, `MintSandVoiceCallSecret`, `VoiceCallHarnessSession`, `VoiceCallHarnessTool`, `SetGrokBotAgentVoice`, `ListGrokBotTranscriptEntries`, `SendGrokBotUserMessage`).
- `public/` — Notch UI (`index.html`, `styles.css`, `app.js`) and the flat Motion Lab character engine (`motion-lab.js`).
- `scripts/` — Build and sign (`build-mac-app.sh`), notarise (`notarise-mac-app.sh`), verify (`verify-mac-app.sh`), install (`install-app.sh`), launch (`launch.sh`), and one-step setup (`setup.sh`).

## Development Workflow

1. Edit UI files in `public/` or server routes in `server.mjs`.
2. Rebuild, sign, and relaunch the native `.app` bundle:
   ```bash
   export CODESIGN_IDENTITY="Developer ID Application: …"
   npm run build:mac && npm start
   ```
3. Browser preview is off. The launch bearer token is injected only into the native `WKWebView` via a Swift `WKUserScript`. HTML served on loopback does not contain the token, so a normal browser cannot call `/api/*`.
