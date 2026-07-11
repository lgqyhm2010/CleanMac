<div align="center">

<img src="Sources/CleanMac/Resources/Images/cleanmac-mascot.png" alt="CleanMac" width="160" />

# CleanMac

**macOS के लिए एक नेटिव, निजी, AI-सहायता प्राप्त डिस्क क्लीनर।**

कैश, लॉग, डुप्लिकेट, बड़ी फ़ाइलें और अप्रयुक्त ऐप्स स्कैन करें, इंस्टॉल किए गए AI CLI से संशोधित मेटाडेटा की समीक्षा करें और उन्हें सुरक्षित रूप से Trash में ले जाएँ। CleanMac में कोई अकाउंट या टेलीमेट्री नहीं है; AI CLI अपने प्रदाता की नेटवर्क सेवा का उपयोग कर सकता है।

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
**हिन्दी** ·
[Português (BR)](README.pt-BR.md) ·
[Русский](README.ru.md) ·
[বাংলা](README.bn.md)

</div>

---

## CleanMac क्या है?

CleanMac एक नेटिव macOS ऐप (SwiftUI) है जो डिस्क स्थान को **सुरक्षित रूप से** वापस पाता है। यह आपके Mac को क्लीनअप उम्मीदवारों के लिए स्कैन करता है — कैश, लॉग, अस्थायी फ़ाइलें, डुप्लिकेट, आकार में बड़ी फ़ाइलें, बचे हुए ऐप डेटा — प्रत्येक को एक जोखिम स्तर सौंपता है, और किसी भी चीज़ को छूने से पहले आपको सब कुछ समीक्षा करने देता है। फ़ाइलें **Trash** में जाती हैं, कभी भी सीधे स्थायी विलोपन में नहीं।

जो इसे अलग बनाता है: यह चुने हुए आइटम का **सीमित संशोधित मेटाडेटा** इंस्टॉल किए गए AI CLI (Claude Code, Codex या Gemini CLI) को दूसरी राय के लिए दे सकता है। आपका प्रश्न जैसा लिखा गया है वैसा ही भेजा जाता है; CleanMac फ़ाइल सामग्री या पूरे पथ नहीं जोड़ता, और CLI कॉन्फ़िगर किए गए प्रदाता से संपर्क कर सकता है।

## विशेषताएँ

- 🧹 **स्मार्ट स्कैन** — कैश, लॉग, अस्थायी फ़ाइलें, Trash, डेवलपर जंक (Xcode derived data), डाउनलोड, और अवर्गीकृत "अन्य" फ़ाइलें।
- 📦 **डुप्लिकेट खोजक** — फ़ाइलों को SHA-256 कंटेंट हैश द्वारा समूहित करता है और सबसे नई प्रति रखता है।
- 🐘 **बड़ी फ़ाइलें** — एक कॉन्फ़िगर करने योग्य सीमा (डिफ़ॉल्ट 500 MB) से अधिक की फ़ाइलों को सामने लाता है।
- 🗑️ **ऐप अनइंस्टॉलर** — चुने हुए ऐप बंडल को Trash में ले जाता है; आकस्मिक डेटा हानि से बचने के लिए उपयोगकर्ता सहायता डेटा को नहीं बदलता।
- 🤖 **AI समीक्षा (स्थानीय)** — एक स्थापित AI CLI से उम्मीदवारों को *हटाने के लिए सुरक्षित*, *जोखिमपूर्ण*, और *समीक्षा की आवश्यकता* में वर्गीकृत करने के लिए कहें।
- 🛡️ **सुरक्षा पहले** — 20+ सुरक्षा नियम और तीन सुरक्षा स्तर सिस्टम, Mail/Messages/Safari, और Keychain डेटा को विलोपन से रोकते हैं।
- 🌍 **11 भाषाएँ** — पूरी तरह से स्थानीयकृत UI जो आपकी सिस्टम भाषा या एक मैन्युअल ओवरराइड का पालन करता है।
- 🔒 **स्पष्ट गोपनीयता सीमा** — CleanMac की कोई टेलीमेट्री या अकाउंट नहीं; AI हस्तांतरण संशोधित और स्पष्ट रूप से बताया गया है।

## AI समीक्षा (स्थानीय)

CleanMac आपके `PATH` पर समर्थित AI CLI का पता लगाता है और अधिकतम 80 उम्मीदवारों की समीक्षा करने देता है। यह आपका प्रश्न और संरचित अनाम मेटाडेटा (आइटम ID, आकार, तारीख, श्रेणी, जोखिम और नियम ID) भेजता है, 120 सेकंड की समय सीमा के साथ एक अनूठी खाली अस्थायी डायरेक्टरी से CLI चलाता है और हर आइटम के ठीक एक बार वर्गीकृत होने पर ही उत्तर स्वीकार करता है।

| टूल | बाइनरी | जिन मॉडलों को आप चुन सकते हैं |
|------|--------|---------------------|
| **Claude Code** | `claude` | Default · Fable · Opus · Sonnet · Haiku |
| **Codex** | `codex` | Default · gpt-5.5 · gpt-5.4 · gpt-5.4-mini |
| **Gemini CLI** | `gemini` | Default · Pro · Flash |

उम्मीदवार सूची और आपका प्रॉम्प्ट एक सबप्रोसेस के रूप में stdin/arguments के माध्यम से CLI को पास किए जाते हैं — **वे कभी आपकी मशीन नहीं छोड़ते**। CleanMac चाइल्ड एनवायरनमेंट से अपने स्वयं के सेशन मार्कर भी हटा देता है ताकि कोई CLI किसी नेस्टेड सेशन का गलत पता न लगा सके।

## गोपनीयता और सुरक्षा

- **AI नेटवर्क खुलासा।** CleanMac में टेलीमेट्री नहीं है, लेकिन इंस्टॉल किया गया AI CLI अपने प्रदाता से संपर्क कर सकता है। समीक्षा आपका प्रश्न जैसा लिखा गया है वैसा ही, अनाम ID और सीमित मेटाडेटा के साथ भेजती है; फ़ाइल सामग्री या अपने आप एकत्र पूरे पथ नहीं भेजती।
- **Trash, `rm` नहीं।** सब कुछ `FileManager.trashItem(at:)` के माध्यम से ले जाया जाता है, ताकि आप इसे पुनर्स्थापित कर सकें।
- **सुरक्षा स्तर।** `allowed` (कैश/लॉग/अस्थायी) → `requiresReview` (सोर्स कोड, क्लाउड स्टोरेज, डाउनलोड, डेव डेटा) → `blocked` (सिस्टम रूट, ऐप डेटा, Mail/Messages/Safari, ब्राउज़र डेटा, Keychain)।
- **Full Disk Access** वैकल्पिक है लेकिन अनुशंसित है ताकि स्कैन संरक्षित Library स्थानों को देख सके। CleanMac System Settings में इसे प्रदान करने में आपका मार्गदर्शन करता है।

## इंस्टॉल करें

### डाउनलोड (अनुशंसित)

1. [Releases पेज](https://github.com/lgqyhm2010/CleanMac/releases/latest) से नवीनतम **`CleanMac.dmg`** प्राप्त करें।
2. DMG खोलें और **CleanMac** को **Applications** में खींचें।

> **पहला लॉन्च:** यदि macOS कहता है कि किसी ऐसे बिल्ड पर जो अभी नोटराइज़्ड नहीं है, ऐप को सत्यापित नहीं किया जा सकता (Gatekeeper), तो ऐप पर राइट-क्लिक करें → **Open**, या चलाएँ:
> ```bash
> xattr -dr com.apple.quarantine /Applications/CleanMac.app
> ```
> आधिकारिक रूप से नोटराइज़्ड रिलीज़ सामान्य डबल-क्लिक के साथ खुलती हैं।

### आवश्यकताएँ

- macOS **14.0 (Sonoma)** या बाद का
- Apple Silicon या Intel

## सोर्स से बिल्ड करें

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

**टूलचेन:** Swift 6.0 (Xcode 16+)। पैकेज एक निष्पादन योग्य टारगेट `CleanMac` (ऐप) और एक लाइब्रेरी टारगेट `CleanMacCore` (लॉजिक, मॉडल, सेवाएँ — परीक्षण योग्यता के लिए अलग रखा गया) प्रदान करता है।

## एक DMG पैकेज करना

एक एकल स्क्रिप्ट ऐप को बिल्ड करती है और एक वितरण योग्य, ड्रैग-टू-इंस्टॉल DMG पैकेज करती है:

```bash
./script/build_dmg.sh          # -> dist/CleanMac.dmg
```

स्क्रिप्ट **साइन और नोटराइज़ करती है** जब Developer ID क्रेडेंशियल्स उपलब्ध होते हैं और अन्यथा **सुगमता से घटती है** (ad-hoc हस्ताक्षर), ताकि यह हमेशा एक DMG उत्पन्न करती है। एनवायरनमेंट वेरिएबल्स के माध्यम से साइनिंग कॉन्फ़िगर करें — कोई भी सीक्रेट कभी हार्ड-कोडेड नहीं होता:

| वेरिएबल | उद्देश्य |
|----------|---------|
| `CODESIGN_IDENTITY` | साइनिंग पहचान, जैसे `Developer ID Application: Name (TEAMID)`। यदि अनसेट है तो स्वतः पता लगाया जाता है। |
| `NOTARY_PROFILE` | एक `notarytool` कीचेन प्रोफ़ाइल नाम ([`docs/RELEASING.md`](docs/RELEASING.md) देखें)। |
| `APPLE_ID` / `APPLE_TEAM_ID` / `APPLE_APP_PASSWORD` | वैकल्पिक नोटराइज़ेशन क्रेडेंशियल्स (CI द्वारा उपयोग किए जाते हैं)। |

> वास्तविक "डाउनलोड-और-खोलें" वितरण के लिए एक भुगतान किए गए **Apple Developer ID Application** प्रमाणपत्र की आवश्यकता होती है। एकबारगी सेटअप के लिए [`docs/RELEASING.md`](docs/RELEASING.md) देखें। इसके बिना, DMG अभी भी बिल्ड होता है लेकिन नोटराइज़्ड नहीं होता।

`main` में प्रत्येक पुश और प्रत्येक टैग GitHub Actions ([`.github/workflows/release-dmg.yml`](.github/workflows/release-dmg.yml)) के माध्यम से स्वतः DMG को फिर से बिल्ड और प्रकाशित करता है।

## स्थानीयकरण

CleanMac **11 भाषाओं** में शिप होता है: अंग्रेज़ी, सरलीकृत चीनी, पारंपरिक चीनी, जापानी, स्पेनिश, फ़्रेंच, अरबी, हिन्दी, पुर्तगाली (ब्राज़ील), रूसी, और बंगाली। UI डिफ़ॉल्ट रूप से आपकी सिस्टम भाषा का पालन करता है और इसे **Settings** में ओवरराइड किया जा सकता है।

स्ट्रिंग्स `L10n` एब्स्ट्रैक्शन के पीछे `Sources/CleanMacCore/Resources/<locale>.lproj/Localizable.strings` में रहती हैं। कोई भाषा जोड़ने के लिए, एक अनुवादित `Localizable.strings` के साथ एक नया `.lproj` फ़ोल्डर जोड़ें, `AppLanguage` में केस जोड़ें, और फिर से बिल्ड करें।

## प्रोजेक्ट संरचना

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

## योगदान

योगदान का स्वागत है! कैसे बिल्ड करें, परीक्षण करें, और एक पुल रिक्वेस्ट खोलें, इसके लिए कृपया [CONTRIBUTING.md](CONTRIBUTING.md) पढ़ें। अनुवाद सुधार और नए लोकेल विशेष रूप से सराहे जाते हैं।

## लाइसेंस

CleanMac [MIT License](LICENSE) के अंतर्गत जारी किया गया है।
