# Setting Up GrokBot Notch with Your Grok Bot

You can have your own **Grok Bot** install, compile, and launch **GrokBot Notch** on your Mac automatically.

## Copy-Paste Prompt for Your Grok Bot

Copy and paste this into any Grok Bot chat (with local shell/computer tools enabled):

```text
Please set up and launch GrokBot Notch on my Mac from https://github.com/danjns-web/grokbot-notch — clone the repo to ~/grokbot-notch, read AGENTS.md, set CODESIGN_IDENTITY to my Developer ID Application identity (do not use Apple Development or ad-hoc), run npm run setup, and confirm GrokBotNotch is running. Do not read or print the launch-auth token file or any Keychain / notary secrets. Unauthenticated curl to http://127.0.0.1:4789/api/bootstrap should return 401.
```

## What Your Grok Bot Will Do

1. Clone `https://github.com/danjns-web/grokbot-notch` to `~/grokbot-notch`.
2. Check that `swiftc` (Xcode Command Line Tools) and `node` (v22.5+ with `node:sqlite`) are available. If `swiftc` is missing, it should print `xcode-select --install` and stop rather than running that command.
3. Compile the native Swift macOS app (`macos/NotchApp.swift`) into `GrokBot Notch.app` and sign it **only** with the `CODESIGN_IDENTITY` you named (`Developer ID Application: …`, hardened runtime, secure timestamp).
4. Start the local Grok Bot bridge on `127.0.0.1:4789` (loopback-only, per-launch bearer token for the native `WKWebView`) and open `GrokBot Notch.app` at the top of your primary display.

To notarise after that (you create the keychain profile yourself with `xcrun notarytool store-credentials`):

```bash
export NOTARY_PROFILE="your-profile-name"
npm run notarise
npm run verify:app
npm run install:app
```
