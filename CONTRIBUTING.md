# Contributing to CleanMac

Thanks for your interest in improving CleanMac! This project is a native macOS
disk cleaner built with SwiftUI + SwiftPM. Contributions of all sizes are
welcome — bug fixes, features, and especially **translation improvements**.

## Getting started

```bash
git clone https://github.com/lgqyhm2010/CleanMac.git
cd CleanMac
swift build          # build everything
swift test           # run the test suites
./script/build_and_run.sh   # build the .app bundle and launch it
```

**Requirements:** macOS 14+ and Swift 6.0 (Xcode 16 or newer).

## Project layout

| Path | What lives here |
|------|-----------------|
| `Sources/CleanMac` | App target — SwiftUI views, stores, the AppKit shell and menus |
| `Sources/CleanMacCore` | Library target — models, services, safety rules, localization |
| `Tests/CleanMacCoreTests` | Core-logic tests |
| `Tests/CleanMacUITests` | App/store tests |
| `script/` | Build & packaging scripts |

Keep logic in `CleanMacCore` (it's covered by tests) and keep `CleanMac`
focused on presentation.

## Making a change

1. **Fork** and create a topic branch (`feat/…`, `fix/…`, `docs/…`).
2. Add or update **tests** in `CleanMacCoreTests` / `CleanMacUITests` for any
   behavior change. CleanMacCore is deliberately UI-free so it can be tested.
3. Run `swift test` and make sure it passes.
4. Keep commits focused and write clear messages.
5. Open a pull request describing **what** changed and **why**.

## Code style

- Follow the conventions already in the surrounding code.
- User-facing strings must go through the `L10n` abstraction — **never hardcode
  display text**. Add the key to `L10n` and provide a value in every locale.
- Prefer moving files to the Trash over destructive deletion; respect the
  existing safety-rule and protection-tier model.

## Translations

CleanMac ships in 11 languages. Strings live in:

```
Sources/CleanMacCore/Resources/<locale>.lproj/Localizable.strings
```

- **Fixing a translation:** edit the relevant `Localizable.strings` and keep the
  keys and any `%@`/`%lld` placeholders identical to `en.lproj`.
- **Adding a language:** create a new `<locale>.lproj/Localizable.strings`, add
  the case to `AppLanguage`, and (optionally) add a `README.<locale>.md`.

## Reporting bugs

Open an issue with your macOS version, steps to reproduce, and what you
expected. Screenshots help.

## License

By contributing, you agree that your contributions are licensed under the
[MIT License](LICENSE).
