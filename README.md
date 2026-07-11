<div align="center">

<img src="Sources/CleanMac/Resources/Images/cleanmac-mascot.png" alt="CleanMac" width="160" />

# CleanMac

**A native, private, AI-assisted disk cleaner for macOS.**

Scan for caches, logs, duplicates, large files and unused apps — review redacted metadata with an AI CLI you installed — and move them safely to the Trash. CleanMac has no account or telemetry; the AI CLI may use its provider's network service.

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

What makes it different: it can hand **bounded, redacted metadata** for selected items to an AI CLI you already installed (Claude Code, Codex, or Gemini CLI) for a second opinion. Your question is sent as written; CleanMac does not add file contents or full paths, and the CLI may contact its configured provider.

## Features

- 🧹 **Smart scan** — caches, logs, temporary files, Trash, developer junk (Xcode derived data), downloads, and unclassified “other” files.
- 📦 **Duplicate finder** — groups files by SHA-256 content hash and keeps the newest copy.
- 🐘 **Large files** — surfaces files over a configurable threshold (default 500 MB).
- 🗑️ **App uninstaller** — moves selected app bundles to the Trash while leaving user support data untouched to prevent accidental data loss.
- 🤖 **AI Review (local)** — ask an installed AI CLI to classify candidates into *safe to delete*, *risky*, and *needs review*.
- 🛡️ **Safety first** — 20+ safety rules and three protection tiers block system, Mail/Messages/Safari, and Keychain data from deletion.
- 🌍 **11 languages** — fully localized UI that follows your system language or a manual override.
- 🔒 **Explicit privacy boundary** — no CleanMac telemetry or account; AI handoff is redacted and disclosed.

## AI Review (Local)

CleanMac detects supported command-line AI tools on your `PATH` (including common Homebrew, npm, asdf and volta locations) and lets you pick one to review up to 80 cleanup candidates. The app sends your question plus structured anonymous metadata (item ID, size, modified date, category, risk and rule IDs), runs the CLI from a unique empty temporary directory with a 120-second timeout, and accepts the reply only when every item is classified exactly once.

| Tool | Binary | Models you can pick |
|------|--------|---------------------|
| **Claude Code** | `claude` | Default · Fable · Opus · Sonnet · Haiku |
| **Codex** | `codex` | Default · gpt-5.5 · gpt-5.4 · gpt-5.4-mini |
| **Gemini CLI** | `gemini` | Default · Pro · Flash |

The candidate list and your prompt are passed to the CLI via stdin/arguments as a subprocess — **they never leave your machine**. CleanMac also strips its own session markers from the child environment so a CLI can't misdetect a nested session.

## Privacy & Safety

- **AI network disclosure.** CleanMac does not implement telemetry, but an installed AI CLI may contact its configured provider. AI review sends your question as written plus anonymous IDs and bounded metadata, never file contents or automatically collected full paths.
- **Trash, not `rm`.** Everything is moved via `FileManager.trashItem(at:)`, so you can restore it.
- **Protection tiers.** `allowed` (caches/logs/temp) → `requiresReview` (source code, cloud storage, downloads, dev data) → `blocked` (system root, app data, Mail/Messages/Safari, browser data, Keychain).
- **Full Disk Access** is optional but recommended so scans can see protected Library locations. CleanMac guides you through granting it in System Settings.

## Install

### Download (recommended)

1. Grab the latest **`CleanMac.dmg`** from the [Releases page](https://github.com/lgqyhm2010/CleanMac/releases/latest).
2. Open the DMG and drag **CleanMac** into **Applications**.

> Official downloads are signed and notarized. If Gatekeeper cannot verify one,
> do not disable quarantine; delete it and download the asset again from the
> official Releases page.

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

A single script builds a universal app and packages a drag-to-install DMG:

```bash
# Local, explicitly non-distributable preview
./script/build_dmg.sh --unsigned

# Distributable release; requires Developer ID and notarization credentials
CLEANMAC_VERSION=1.0.0 CLEANMAC_BUILD_NUMBER=1 \
  NOTARY_PROFILE=CleanMacNotary ./script/build_dmg.sh --release
```

Formal releases fail closed: a missing credential, invalid version, architecture,
signing, notarization, stapling, or Gatekeeper check stops the build. Configure
release metadata and signing via environment variables; secrets are never
hard-coded:

| Variable | Purpose |
|----------|---------|
| `CODESIGN_IDENTITY` | Signing identity, e.g. `Developer ID Application: Name (TEAMID)`. Auto-detected if unset. |
| `CLEANMAC_VERSION` / `CLEANMAC_BUILD_NUMBER` | Release version and numeric build number. |
| `NOTARY_PROFILE` | A `notarytool` keychain profile name (see [`docs/RELEASING.md`](docs/RELEASING.md)). |
| `APPLE_ID` / `APPLE_TEAM_ID` / `APPLE_APP_PASSWORD` | Alternative notarization credentials (used by CI). |

> `--unsigned` is only for local/PR validation and is never published as a release. See [`docs/RELEASING.md`](docs/RELEASING.md) for setup.

Pull requests and pushes to `main` build a read-only unsigned preview. Only a `v*` tag can publish, after the signed and notarized release passes every check ([workflow](.github/workflows/release-dmg.yml)).

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
