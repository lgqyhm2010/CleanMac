<div align="center">

<img src="Sources/CleanMac/Resources/Images/cleanmac-mascot.png" alt="CleanMac" width="160" />

# CleanMac

**macOS-এর জন্য একটি নেটিভ, ব্যক্তিগত, AI-সহায়তাপ্রাপ্ত ডিস্ক ক্লিনার।**

ক্যাশ, লগ, ডুপ্লিকেট, বড় ফাইল ও অব্যবহৃত অ্যাপ স্ক্যান করুন — একটি লোকাল AI CLI দিয়ে সেগুলো পর্যালোচনা করুন — এবং সেগুলো নিরাপদে Trash-এ সরিয়ে দিন। কোনো অ্যাকাউন্ট নেই, কোনো টেলিমেট্রি নেই, কোনো নেটওয়ার্ক নেই।

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS%2014%2B-black.svg)](#requirements)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Download](https://img.shields.io/badge/Download-.dmg-blue.svg)](https://github.com/lgqyhm2010/CleanMac/releases/latest)

[English](README.md) ·
[简体中文](README.zh-Hans.md) ·
[繁體中文](README.zh-Hant.md) ·
[日本語](README.ja.md) ·
[Español](README.es.md) ·
[Français](README.fr.md) ·
[العربية](README.ar.md) ·
[हिन्दी](README.hi.md) ·
[Português (BR)](README.pt-BR.md) ·
[Русский](README.ru.md) ·
**বাংলা**

</div>

---

## CleanMac কী?

CleanMac একটি নেটিভ macOS অ্যাপ (SwiftUI) যা ডিস্কের জায়গা **নিরাপদে** ফিরিয়ে দেয়। এটি আপনার Mac-এ ক্লিনআপের উপযুক্ত জিনিস খুঁজে বের করে — ক্যাশ, লগ, অস্থায়ী ফাইল, ডুপ্লিকেট, অতিরিক্ত বড় ফাইল, অবশিষ্ট অ্যাপ ডেটা — প্রতিটিকে একটি ঝুঁকির মাত্রা নির্ধারণ করে, এবং কিছু স্পর্শ করার আগে আপনাকে সবকিছু পর্যালোচনা করতে দেয়। ফাইল **Trash**-এ যায়, কখনোই সরাসরি স্থায়ী মুছে ফেলার দিকে নয়।

যা একে আলাদা করে তোলে: এটি মুছে ফেলার তালিকাটি একটি দ্বিতীয় মতামতের জন্য আপনার **ইতিমধ্যে ইনস্টল করা লোকাল AI CLI**-এর (Claude Code, Codex, বা Gemini CLI) হাতে তুলে দিতে পারে, কোনটি অপসারণ করা নিরাপদ তা নিয়ে। AI আপনার মেশিনেই চলে; কিছুই আপলোড করা হয় না।

## বৈশিষ্ট্য

- 🧹 **স্মার্ট স্ক্যান** — ক্যাশ, লগ, অস্থায়ী ফাইল, Trash, ডেভেলপার জাঙ্ক (Xcode derived data), ডাউনলোড, এবং শ্রেণিবিন্যাসহীন “অন্যান্য” ফাইল।
- 📦 **ডুপ্লিকেট ফাইন্ডার** — SHA-256 কনটেন্ট হ্যাশ অনুযায়ী ফাইল গ্রুপ করে এবং সবচেয়ে নতুন কপিটি রাখে।
- 🐘 **বড় ফাইল** — একটি কনফিগারযোগ্য থ্রেশহোল্ডের (ডিফল্ট 500 MB) চেয়ে বড় ফাইলগুলো সামনে আনে।
- 🗑️ **অ্যাপ আনইনস্টলার** — একটি অ্যাপ *এবং* এর অবশিষ্ট সাপোর্ট ফাইলগুলো (Preferences, Caches, Application Support) সরিয়ে দেয়, যা bundle ID-এর সাথে যুক্ত।
- 🤖 **AI Review (লোকাল)** — একটি ইনস্টল করা AI CLI-কে বলুন প্রার্থীদের *মুছে ফেলা নিরাপদ*, *ঝুঁকিপূর্ণ*, এবং *পর্যালোচনা প্রয়োজন*-এ শ্রেণিবদ্ধ করতে।
- 🛡️ **নিরাপত্তা প্রথম** — ২০+ নিরাপত্তা নিয়ম এবং তিনটি সুরক্ষা স্তর সিস্টেম, Mail/Messages/Safari, এবং Keychain ডেটাকে মুছে ফেলা থেকে আটকায়।
- 🌍 **১১টি ভাষা** — সম্পূর্ণ স্থানীয়কৃত UI যা আপনার সিস্টেম ভাষা বা একটি ম্যানুয়াল ওভাররাইড অনুসরণ করে।
- 🔒 **নকশাগতভাবে ব্যক্তিগত** — কোনো নেটওয়ার্ক কল নেই, কোনো টেলিমেট্রি নেই, কোনো অ্যাকাউন্ট নেই।

## AI Review (লোকাল)

CleanMac আপনার `PATH`-এ সমর্থিত কমান্ড-লাইন AI টুল শনাক্ত করে (সাধারণ Homebrew, npm, asdf এবং volta লোকেশন সহ) এবং আপনাকে ক্লিনআপ প্রার্থীদের একটি ব্যাচ পর্যালোচনা করার জন্য একটি বেছে নিতে দেয়। অ্যাপটি একটি কাঠামোবদ্ধ JSON প্রম্পট তৈরি করে (পাথ, সাইজ, পরিবর্তনের তারিখ, ক্যাটাগরি, ঝুঁকি, এবং প্রযোজ্য নিরাপত্তা নিয়ম), CLI-টি **আপনার হোম ডিরেক্টরি থেকে** চালায়, এবং উত্তরটিকে রঙ-কোডেড গ্রুপে পার্স করে ফেরত আনে।

| Tool | Binary | আপনি যে মডেল বেছে নিতে পারেন |
|------|--------|---------------------|
| **Claude Code** | `claude` | Default · Fable · Opus · Sonnet · Haiku |
| **Codex** | `codex` | Default · gpt-5.5 · gpt-5.4 · gpt-5.4-mini |
| **Gemini CLI** | `gemini` | Default · Pro · Flash |

প্রার্থী তালিকা এবং আপনার প্রম্পট একটি সাবপ্রসেস হিসেবে stdin/arguments-এর মাধ্যমে CLI-তে পাঠানো হয় — **সেগুলো কখনোই আপনার মেশিন ছেড়ে যায় না**। CleanMac চাইল্ড এনভায়রনমেন্ট থেকে নিজের সেশন মার্কারগুলোও সরিয়ে দেয় যাতে একটি CLI ভুলভাবে কোনো নেস্টেড সেশন শনাক্ত করতে না পারে।

## গোপনীয়তা ও নিরাপত্তা

- **কোনো নেটওয়ার্ক নেই।** CleanMac কোনো নেটওয়ার্ক কল করে না। AI পর্যালোচনা আপনার নিজে ইনস্টল করা CLI-এর মাধ্যমে লোকালি ঘটে।
- **Trash, `rm` নয়।** সবকিছু `FileManager.trashItem(at:)`-এর মাধ্যমে সরানো হয়, তাই আপনি সেটি পুনরুদ্ধার করতে পারেন।
- **সুরক্ষা স্তর।** `allowed` (ক্যাশ/লগ/temp) → `requiresReview` (সোর্স কোড, ক্লাউড স্টোরেজ, ডাউনলোড, ডেভ ডেটা) → `blocked` (সিস্টেম রুট, অ্যাপ ডেটা, Mail/Messages/Safari, ব্রাউজার ডেটা, Keychain)।
- **Full Disk Access** ঐচ্ছিক তবে প্রস্তাবিত, যাতে স্ক্যান সুরক্ষিত Library লোকেশনগুলো দেখতে পারে। CleanMac System Settings-এ এটি অনুমোদন করার প্রক্রিয়ায় আপনাকে গাইড করে।

## ইনস্টল

### ডাউনলোড (প্রস্তাবিত)

1. [Releases page](https://github.com/lgqyhm2010/CleanMac/releases/latest) থেকে সর্বশেষ **`CleanMac.dmg`** নিন।
2. DMG খুলুন এবং **CleanMac**-কে **Applications**-এ টেনে আনুন।

> **প্রথম লঞ্চ:** যদি macOS বলে যে অ্যাপটি যাচাই করা যাচ্ছে না (Gatekeeper) এমন একটি বিল্ডে যা এখনও নোটারাইজড নয়, তাহলে অ্যাপটিতে রাইট-ক্লিক করুন → **Open**, অথবা চালান:
> ```bash
> xattr -dr com.apple.quarantine /Applications/CleanMac.app
> ```
> আনুষ্ঠানিকভাবে নোটারাইজড রিলিজগুলো একটি সাধারণ ডাবল-ক্লিকে খোলে।

### প্রয়োজনীয়তা

- macOS **14.0 (Sonoma)** বা পরবর্তী
- Apple Silicon বা Intel

## সোর্স থেকে বিল্ড

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

**টুলচেইন:** Swift 6.0 (Xcode 16+)। প্যাকেজটি একটি এক্সিকিউটেবল টার্গেট `CleanMac` (অ্যাপ) এবং একটি লাইব্রেরি টার্গেট `CleanMacCore` (লজিক, মডেল, সার্ভিস — টেস্টযোগ্যতার জন্য আলাদা রাখা হয়েছে) উন্মুক্ত করে।

## একটি DMG প্যাকেজ করা

একটি একক স্ক্রিপ্ট অ্যাপটি বিল্ড করে এবং একটি বিতরণযোগ্য, টেনে-ইনস্টল-করা DMG প্যাকেজ করে:

```bash
./script/build_dmg.sh          # -> dist/CleanMac.dmg
```

Developer ID শংসাপত্র উপলব্ধ থাকলে স্ক্রিপ্টটি **সাইন ও নোটারাইজ** করে এবং অন্যথায় **সুন্দরভাবে অবনমিত হয়** (ad-hoc স্বাক্ষর), তাই এটি সবসময় একটি DMG তৈরি করে। এনভায়রনমেন্ট ভেরিয়েবলের মাধ্যমে সাইনিং কনফিগার করুন — কোনো সিক্রেট কখনোই হার্ড-কোড করা হয় না:

| Variable | উদ্দেশ্য |
|----------|---------|
| `CODESIGN_IDENTITY` | সাইনিং আইডেন্টিটি, যেমন `Developer ID Application: Name (TEAMID)`। সেট না থাকলে স্বয়ংক্রিয়ভাবে শনাক্ত হয়। |
| `NOTARY_PROFILE` | একটি `notarytool` keychain প্রোফাইল নাম ([`docs/RELEASING.md`](docs/RELEASING.md) দেখুন)। |
| `APPLE_ID` / `APPLE_TEAM_ID` / `APPLE_APP_PASSWORD` | বিকল্প নোটারাইজেশন শংসাপত্র (CI দ্বারা ব্যবহৃত)। |

> প্রকৃত “ডাউনলোড-এবং-খোলা” বিতরণের জন্য একটি পেইড **Apple Developer ID Application** সার্টিফিকেট প্রয়োজন। একবারের সেটআপের জন্য [`docs/RELEASING.md`](docs/RELEASING.md) দেখুন। এটি ছাড়া, DMG-টি এখনও বিল্ড হয় তবে নোটারাইজড হয় না।

`main`-এ প্রতিটি push এবং প্রতিটি ট্যাগ স্বয়ংক্রিয়ভাবে GitHub Actions ([`.github/workflows/release-dmg.yml`](.github/workflows/release-dmg.yml)) এর মাধ্যমে DMG-টি পুনরায় বিল্ড ও প্রকাশ করে।

## স্থানীয়করণ

CleanMac **১১টি ভাষায়** আসে: English, Simplified Chinese, Traditional Chinese, Japanese, Spanish, French, Arabic, Hindi, Portuguese (Brazil), Russian, এবং Bengali। UI ডিফল্টভাবে আপনার সিস্টেম ভাষা অনুসরণ করে এবং **Settings**-এ ওভাররাইড করা যায়।

স্ট্রিংগুলো `L10n` অ্যাবস্ট্রাকশনের পেছনে `Sources/CleanMacCore/Resources/<locale>.lproj/Localizable.strings`-এ থাকে। একটি ভাষা যোগ করতে, একটি অনূদিত `Localizable.strings` সহ একটি নতুন `.lproj` ফোল্ডার যোগ করুন, `AppLanguage`-এ কেসটি যোগ করুন, এবং পুনরায় বিল্ড করুন।

## প্রকল্প কাঠামো

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

## অবদান

অবদান স্বাগত! কীভাবে বিল্ড, টেস্ট, এবং একটি pull request খুলতে হয় তা জানতে অনুগ্রহ করে [CONTRIBUTING.md](CONTRIBUTING.md) পড়ুন। অনুবাদ সংশোধন এবং নতুন লোকেল বিশেষভাবে প্রশংসিত।

## লাইসেন্স

CleanMac [MIT License](LICENSE)-এর অধীনে প্রকাশিত।
