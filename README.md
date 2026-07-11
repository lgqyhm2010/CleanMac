<div align="center">

<img src="Sources/CleanMac/Resources/Images/cleanmac-mascot.png" alt="CleanMac" width="160" />

# CleanMac

**A native, private, AI-assisted disk cleaner for macOS.**

Scan for caches, logs, duplicates, large files and unused apps — review them with a local AI CLI — and move them safely to the Trash. No account, no telemetry, no network.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS%2014%2B-black.svg)](#requirements)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Download](https://img.shields.io/badge/Download-.dmg-blue.svg)](https://github.com/lgqyhm2010/CleanMac/releases/latest)

**English** ·
[简体中文](README.zh-Hans.md) ·
[繁體中文](README.zh-Hant.md) ·
[日本語](README.ja.md) ·
[Español](README.es.md) ·
[Français](README.fr.md) ·
[العربية](README.ar.md) ·
[हिन्दी](README.hi.md) ·
[Português (BR)](README.pt-BR.md) ·
[Русский](README.ru.md) ·
[বাংলা](README.bn.md)

</div>

---

## What is CleanMac?

CleanMac is a native macOS app (SwiftUI) that reclaims disk space **safely**. It scans your Mac for cleanup candidates — caches, logs, temporary files, duplicates, oversized files, leftover app data — assigns each a risk level, and lets you review everything before anything is touched. Files go to the **Trash**, never straight to permanent deletion.

What makes it different: it can hand the deletion list to a **local AI CLI you already have installed** (Claude Code, Codex, or Gemini CLI) for a second opinion on what is safe to remove. The AI runs on your machine; nothing is uploaded.

## Features

- 🧹 **Smart scan** — caches, logs, temporary files, Trash, developer junk (Xcode derived data), downloads, and unclassified “other” files.
- 📦 **Duplicate finder** — groups files by SHA-256 content hash and keeps the newest copy.
- 🐘 **Large files** — surfaces files over a configurable threshold (default 500 MB).
- 🗑️ **App uninstaller** — moves selected app bundles to the Trash while leaving user support data untouched to prevent accidental data loss.
- 🤖 **AI Review (local)** — ask an installed AI CLI to classify candidates into *safe to delete*, *risky*, and *needs review*.
- 🛡️ **Safety first** — 20+ safety rules and three protection tiers block system, Mail/Messages/Safari, and Keychain data from deletion.
- 🌍 **11 languages** — fully localized UI that follows your system language or a manual override.
- 🔒 **Private by design** — no network calls, no telemetry, no account.

## AI Review (Local)

CleanMac detects supported command-line AI tools on your `PATH` (including common Homebrew, npm, asdf and volta locations) and lets you pick one to review a batch of cleanup candidates. The app builds a structured JSON prompt (path, size, modified date, category, risk, and the safety rules that apply), runs the CLI **from your home directory**, and parses the reply back into color-coded groups.

| Tool | Binary | Models you can pick |
|------|--------|---------------------|
| **Claude Code** | `claude` | Default · Fable · Opus · Sonnet · Haiku |
| **Codex** | `codex` | Default · gpt-5.5 · gpt-5.4 · gpt-5.4-mini |
| **Gemini CLI** | `gemini` | Default · Pro · Flash |

The candidate list and your prompt are passed to the CLI via stdin/arguments as a subprocess — **they never leave your machine**. CleanMac also strips its own session markers from the child environment so a CLI can't misdetect a nested session.

## Privacy & Safety

- **No network.** CleanMac makes no network calls. AI review happens locally through CLIs you installed yourself.
- **Trash, not `rm`.** Everything is moved via `FileManager.trashItem(at:)`, so you can restore it.
- **Protection tiers.** `allowed` (caches/logs/temp) → `requiresReview` (source code, cloud storage, downloads, dev data) → `blocked` (system root, app data, Mail/Messages/Safari, browser data, Keychain).
- **Full Disk Access** is optional but recommended so scans can see protected Library locations. CleanMac guides you through granting it in System Settings.

## Install

### Download (recommended)

1. Grab the latest **`CleanMac.dmg`** from the [Releases page](https://github.com/lgqyhm2010/CleanMac/releases/latest).
2. Open the DMG and drag **CleanMac** into **Applications**.

> **First launch:** If macOS says the app can’t be verified (Gatekeeper) on a build that isn’t notarized yet, right-click the app → **Open**, or run:
> ```bash
> xattr -dr com.apple.quarantine /Applications/CleanMac.app
> ```
> Officially notarized releases open with a normal double-click.

### Requirements

- macOS **14.0 (Sonoma)** or later
- Apple Silicon or Intel

## Build from source

```bash
git clone https://github.com/lgqyhm2010/CleanMac.git
cd CleanMac

# Build & run the app bundle (creates dist/CleanMac.app and launches it)
./script/build_and_run.sh

# Or just build with SwiftPM
swift build --product CleanMac

# Run the tests
swift test
```

**Toolchain:** Swift 6.0 (Xcode 16+). The package exposes an executable target `CleanMac` (the app) and a library target `CleanMacCore` (logic, models, services — kept separate for testability).

## Packaging a DMG

A single script builds the app and packages a distributable, drag-to-install DMG:

```bash
./script/build_dmg.sh          # -> dist/CleanMac.dmg
```

The script **signs and notarizes** when Developer ID credentials are available and **degrades gracefully** (ad-hoc signature) otherwise, so it always produces a DMG. Configure signing via environment variables — no secrets are ever hard-coded:

| Variable | Purpose |
|----------|---------|
| `CODESIGN_IDENTITY` | Signing identity, e.g. `Developer ID Application: Name (TEAMID)`. Auto-detected if unset. |
| `NOTARY_PROFILE` | A `notarytool` keychain profile name (see [`docs/RELEASING.md`](docs/RELEASING.md)). |
| `APPLE_ID` / `APPLE_TEAM_ID` / `APPLE_APP_PASSWORD` | Alternative notarization credentials (used by CI). |

> Real “download-and-open” distribution requires a paid **Apple Developer ID Application** certificate. See [`docs/RELEASING.md`](docs/RELEASING.md) for the one-time setup. Without it, the DMG is still built but is not notarized.

Every push to `main` and every tag automatically rebuilds and publishes the DMG via GitHub Actions ([`.github/workflows/release-dmg.yml`](.github/workflows/release-dmg.yml)).

## Localization

CleanMac ships in **11 languages**: English, Simplified Chinese, Traditional Chinese, Japanese, Spanish, French, Arabic, Hindi, Portuguese (Brazil), Russian, and Bengali. The UI follows your system language by default and can be overridden in **Settings**.

Strings live in `Sources/CleanMacCore/Resources/<locale>.lproj/Localizable.strings` behind the `L10n` abstraction. To add a language, add a new `.lproj` folder with a translated `Localizable.strings`, add the case to `AppLanguage`, and rebuild.

## Project structure

```
Sources/
  CleanMac/          App target — SwiftUI views, stores, AppKit shell, menus
  CleanMacCore/      Library target — models, services, safety rules, localization
Tests/
  CleanMacCoreTests/ Core logic tests
  CleanMacUITests/   App/store tests
script/
  build_and_run.sh   Build the .app bundle and launch it
  build_dmg.sh       Build + package (and sign/notarize) a DMG
```

## Contributing

Contributions are welcome! Please read [CONTRIBUTING.md](CONTRIBUTING.md) for how to build, test, and open a pull request. Translation fixes and new locales are especially appreciated.

## License

CleanMac is released under the [MIT License](LICENSE).
