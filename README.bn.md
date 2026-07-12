<div align="center">

<img src="Sources/CleanMac/Resources/Images/cleanmac-mascot.png" alt="CleanMac" width="160" />

# CleanMac

**macOS-এর জন্য একটি নেটিভ, ব্যক্তিগত, AI-সহায়তাপ্রাপ্ত ডিস্ক ক্লিনার।**

ক্যাশ, লগ, ডুপ্লিকেট, বড় ফাইল ও অব্যবহৃত অ্যাপ স্ক্যান করুন, ইনস্টল করা AI CLI দিয়ে সংক্ষিপ্ত মেটাডেটা পর্যালোচনা করুন এবং নিরাপদে Trash-এ সরিয়ে দিন। CleanMac-এর কোনো অ্যাকাউন্ট বা টেলিমেট্রি নেই; AI CLI তার প্রদানকারীর নেটওয়ার্ক সেবা ব্যবহার করতে পারে।

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

যা একে আলাদা করে তোলে: নির্বাচিত আইটেমের **সীমাবদ্ধ সংক্ষিপ্ত মেটাডেটা** ইনস্টল করা AI CLI-কে (Claude Code, Codex বা Gemini CLI) দিয়ে দ্বিতীয় মতামত নেওয়া যায়। আপনার প্রশ্নটি যেমন লেখা হয়েছে তেমনই পাঠানো হয়; CleanMac ফাইলের বিষয়বস্তু বা পূর্ণ পথ যোগ করে না, আর CLI কনফিগার করা প্রদানকারীর সঙ্গে যোগাযোগ করতে পারে।

## বৈশিষ্ট্য

- 🧹 **স্মার্ট স্ক্যান** — ক্যাশ, লগ, অস্থায়ী ফাইল, Trash, ডেভেলপার জাঙ্ক (Xcode derived data), ডাউনলোড, এবং শ্রেণিবিন্যাসহীন “অন্যান্য” ফাইল।
- 📦 **ডুপ্লিকেট ফাইন্ডার** — SHA-256 কনটেন্ট হ্যাশ অনুযায়ী ফাইল গ্রুপ করে এবং সবচেয়ে নতুন কপিটি রাখে।
- 🐘 **বড় ফাইল** — একটি কনফিগারযোগ্য থ্রেশহোল্ডের (ডিফল্ট 500 MB) চেয়ে বড় ফাইলগুলো সামনে আনে।
- 🗑️ **অ্যাপ আনইনস্টলার** — নির্বাচিত অ্যাপ বান্ডল ট্র্যাশে সরায়; দুর্ঘটনাজনিত ডেটা হারানো এড়াতে ব্যবহারকারীর সাপোর্ট ডেটা অপরিবর্তিত রাখে।
- 🤖 **AI Review (লোকাল)** — একটি ইনস্টল করা AI CLI-কে বলুন প্রার্থীদের *মুছে ফেলা নিরাপদ*, *ঝুঁকিপূর্ণ*, এবং *পর্যালোচনা প্রয়োজন*-এ শ্রেণিবদ্ধ করতে।
- 🛡️ **নিরাপত্তা প্রথম** — ২০+ নিরাপত্তা নিয়ম এবং তিনটি সুরক্ষা স্তর সিস্টেম, Mail/Messages/Safari, এবং Keychain ডেটাকে মুছে ফেলা থেকে আটকায়।
- 🌍 **১১টি ভাষা** — সম্পূর্ণ স্থানীয়কৃত UI যা আপনার সিস্টেম ভাষা বা একটি ম্যানুয়াল ওভাররাইড অনুসরণ করে।
- 🔒 **স্পষ্ট গোপনীয়তা সীমা** — CleanMac-এর টেলিমেট্রি বা অ্যাকাউন্ট নেই; AI-তে হস্তান্তর সংক্ষিপ্ত ও স্পষ্টভাবে জানানো হয়।

## AI Review (লোকাল)

CleanMac আপনার `PATH`-এ সমর্থিত AI CLI শনাক্ত করে এবং সর্বোচ্চ 80টি প্রার্থী পর্যালোচনা করতে দেয়। এটি আপনার প্রশ্ন ও কাঠামোবদ্ধ বেনামী মেটাডেটা (আইটেম ID, আকার, তারিখ, বিভাগ, ঝুঁকি ও নিয়ম ID) পাঠায়, 120 সেকেন্ড সময়সীমাসহ একটি অনন্য খালি অস্থায়ী ডিরেক্টরি থেকে CLI চালায় এবং প্রতিটি আইটেম ঠিক একবার শ্রেণিবদ্ধ হলেই উত্তর গ্রহণ করে।

| Tool | Binary | আপনি যে মডেল বেছে নিতে পারেন |
|------|--------|---------------------|
| **Claude Code** | `claude` | Default · Fable · Opus · Sonnet · Haiku |
| **Codex** | `codex` | Default · gpt-5.5 · gpt-5.4 · gpt-5.4-mini |
| **Gemini CLI** | `gemini` | Default · Pro · Flash |

প্রার্থী তালিকা এবং আপনার প্রম্পট একটি সাবপ্রসেস হিসেবে stdin/arguments-এর মাধ্যমে CLI-তে পাঠানো হয় — **সেগুলো কখনোই আপনার মেশিন ছেড়ে যায় না**। CleanMac চাইল্ড এনভায়রনমেন্ট থেকে নিজের সেশন মার্কারগুলোও সরিয়ে দেয় যাতে একটি CLI ভুলভাবে কোনো নেস্টেড সেশন শনাক্ত করতে না পারে।

## গোপনীয়তা ও নিরাপত্তা

- **AI নেটওয়ার্ক প্রকাশ।** CleanMac-এ টেলিমেট্রি নেই, কিন্তু ইনস্টল করা AI CLI তার প্রদানকারীর সঙ্গে যোগাযোগ করতে পারে। পর্যালোচনা আপনার প্রশ্নটি অপরিবর্তিতভাবে, বেনামী ID ও সীমাবদ্ধ মেটাডেটাসহ পাঠায়; ফাইলের বিষয়বস্তু বা স্বয়ংক্রিয়ভাবে সংগ্রহ করা পূর্ণ পথ পাঠায় না।
- **Trash, `rm` নয়।** সবকিছু `FileManager.trashItem(at:)`-এর মাধ্যমে সরানো হয়, তাই আপনি সেটি পুনরুদ্ধার করতে পারেন।
- **সুরক্ষা স্তর।** `allowed` (ক্যাশ/লগ/temp) → `requiresReview` (সোর্স কোড, ক্লাউড স্টোরেজ, ডাউনলোড, ডেভ ডেটা) → `blocked` (সিস্টেম রুট, অ্যাপ ডেটা, Mail/Messages/Safari, ব্রাউজার ডেটা, Keychain)।
- **Full Disk Access** ঐচ্ছিক তবে প্রস্তাবিত, যাতে স্ক্যান সুরক্ষিত Library লোকেশনগুলো দেখতে পারে। CleanMac System Settings-এ এটি অনুমোদন করার প্রক্রিয়ায় আপনাকে গাইড করে।

## ইনস্টল

### ডাউনলোড (প্রস্তাবিত)

1. [Releases page](https://github.com/lgqyhm2010/CleanMac/releases/latest) থেকে সর্বশেষ **`CleanMac.dmg`** নিন।
2. DMG খুলুন এবং **CleanMac**-কে **Applications**-এ টেনে আনুন।

> অফিসিয়াল ডাউনলোড সাইন ও নোটারাইজড। Gatekeeper যাচাই করতে না পারলে quarantine বন্ধ করবেন না; ফাইলটি মুছে অফিসিয়াল Releases পেজ থেকে আবার ডাউনলোড করুন।

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
# কেবল স্থানীয়, বিতরণ-অযোগ্য preview
./script/build_dmg.sh --unsigned

# আনুষ্ঠানিক release; Developer ID ও notarization credentials আবশ্যক
CLEANMAC_VERSION=1.0.0 CLEANMAC_BUILD_NUMBER=1 \
  NOTARY_PROFILE=CleanMacNotary ./script/build_dmg.sh --release
```

আনুষ্ঠানিক release fail-closed: credential, version, architecture, signing, notarization, stapling বা Gatekeeper ব্যর্থ হলে build বন্ধ হয়। Environment variables দিয়ে কনফিগার করা হয় এবং secrets hard-code করা হয় না:

| Variable | উদ্দেশ্য |
|----------|---------|
| `CODESIGN_IDENTITY` | সাইনিং আইডেন্টিটি, যেমন `Developer ID Application: Name (TEAMID)`। সেট না থাকলে স্বয়ংক্রিয়ভাবে শনাক্ত হয়। |
| `CLEANMAC_VERSION` / `CLEANMAC_BUILD_NUMBER` | Release version ও numeric build number। |
| `NOTARY_PROFILE` | একটি `notarytool` keychain প্রোফাইল নাম ([`docs/RELEASING.md`](docs/RELEASING.md) দেখুন)। |
| `APPLE_ID` / `APPLE_TEAM_ID` / `APPLE_APP_PASSWORD` | বিকল্প নোটারাইজেশন শংসাপত্র (CI দ্বারা ব্যবহৃত)। |

> `--unsigned` শুধু local/PR validation-এর জন্য এবং formal release হিসেবে প্রকাশিত হয় না। [`docs/RELEASING.md`](docs/RELEASING.md) দেখুন।

PR ও `main` push কেবল read-only unsigned preview বানায়। সব check সফল হলে শুধু `v*` tag প্রকাশ করতে পারে ([workflow](.github/workflows/release-dmg.yml))।

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
