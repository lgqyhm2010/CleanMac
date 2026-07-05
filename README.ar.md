<div align="center">

<img src="Sources/CleanMac/Resources/Images/cleanmac-mascot.png" alt="CleanMac" width="160" />

# CleanMac

**أداة أصلية وخاصة لتنظيف القرص على macOS بمساعدة الذكاء الاصطناعي.**

افحص بحثًا عن ذاكرات التخزين المؤقت والسجلّات والملفات المكررة والملفات الكبيرة والتطبيقات غير المستخدمة — راجعها باستخدام أداة ذكاء اصطناعي محلية عبر سطر الأوامر — وانقلها بأمان إلى Trash. بلا حساب، بلا قياس عن بُعد، بلا شبكة.

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
**العربية** ·
[हिन्दी](README.hi.md) ·
[Português (BR)](README.pt-BR.md) ·
[Русский](README.ru.md) ·
[বাংলা](README.bn.md)

</div>

---

## ما هو CleanMac؟

CleanMac هو تطبيق أصلي على macOS (مبني بـ SwiftUI) يستعيد مساحة القرص **بأمان**. يفحص جهاز Mac الخاص بك بحثًا عن العناصر المرشحة للتنظيف — ذاكرات التخزين المؤقت والسجلّات والملفات المؤقتة والملفات المكررة والملفات المفرطة الحجم وبيانات التطبيقات المتبقية — ويعيّن لكل منها مستوى خطورة، ويتيح لك مراجعة كل شيء قبل المساس بأي شيء. تذهب الملفات إلى **Trash**، وليس مباشرةً إلى الحذف النهائي.

ما يميّزه: بإمكانه تسليم قائمة الحذف إلى **أداة ذكاء اصطناعي محلية عبر سطر الأوامر تكون مثبّتة لديك بالفعل** (Claude Code أو Codex أو Gemini CLI) للحصول على رأي ثانٍ حول ما هو آمن للإزالة. يعمل الذكاء الاصطناعي على جهازك؛ ولا يُرفع أي شيء.

## المزايا

- 🧹 **فحص ذكي** — ذاكرات التخزين المؤقت والسجلّات والملفات المؤقتة وTrash ومخلفات المطوّرين (بيانات Xcode المشتقّة) والتنزيلات والملفات "الأخرى" غير المصنّفة.
- 📦 **باحث المكررات** — يجمّع الملفات حسب تجزئة المحتوى SHA-256 ويُبقي على أحدث نسخة.
- 🐘 **الملفات الكبيرة** — يُظهر الملفات التي تتجاوز عتبة قابلة للضبط (الافتراضي 500 MB).
- 🗑️ **مُزيل التطبيقات** — يزيل تطبيقًا *و* ملفاته المتبقية للدعم (Preferences وCaches وApplication Support) المرتبطة بمعرّف الحزمة (bundle ID).
- 🤖 **مراجعة الذكاء الاصطناعي (محليًا)** — اطلب من أداة ذكاء اصطناعي مثبّتة عبر سطر الأوامر تصنيف العناصر المرشحة إلى *آمنة للحذف* و*محفوفة بالمخاطر* و*تحتاج مراجعة*.
- 🛡️ **الأمان أولًا** — أكثر من 20 قاعدة أمان وثلاث طبقات حماية تمنع حذف بيانات النظام وMail/Messages/Safari وKeychain.
- 🌍 **11 لغة** — واجهة مستخدم مترجَمة بالكامل تتبع لغة نظامك أو تجاوزًا يدويًا.
- 🔒 **الخصوصية بالتصميم** — بلا اتصالات شبكية، بلا قياس عن بُعد، بلا حساب.

## مراجعة الذكاء الاصطناعي (محليًا)

يكتشف CleanMac أدوات الذكاء الاصطناعي المدعومة عبر سطر الأوامر الموجودة في مسار `PATH` لديك (بما في ذلك مواقع Homebrew وnpm وasdf وvolta الشائعة) ويتيح لك اختيار إحداها لمراجعة دفعة من العناصر المرشحة للتنظيف. يبني التطبيق موجِّهًا منظّمًا بصيغة JSON (المسار والحجم وتاريخ التعديل والفئة والخطورة وقواعد الأمان المنطبقة)، ويشغّل الأداة عبر سطر الأوامر **من مجلد المنزل الخاص بك**، ثم يحلّل الرد ويعيده إلى مجموعات مرمَّزة بالألوان.

| الأداة | الملف التنفيذي | النماذج التي يمكنك اختيارها |
|------|--------|---------------------|
| **Claude Code** | `claude` | Default · Fable · Opus · Sonnet · Haiku |
| **Codex** | `codex` | Default · gpt-5.5 · gpt-5.4 · gpt-5.4-mini |
| **Gemini CLI** | `gemini` | Default · Pro · Flash |

تُمرَّر قائمة العناصر المرشحة وموجِّهك إلى الأداة عبر سطر الأوامر من خلال stdin/الوسائط كعملية فرعية — **وهي لا تغادر جهازك أبدًا**. كما يزيل CleanMac علامات الجلسة الخاصة به من بيئة العملية الفرعية حتى لا تسيء الأداة اكتشاف جلسة متداخلة.

## الخصوصية والأمان

- **بلا شبكة.** لا يجري CleanMac أي اتصالات شبكية. تحدث مراجعة الذكاء الاصطناعي محليًا عبر أدوات سطر الأوامر التي ثبّتها بنفسك.
- **Trash، وليس `rm`.** يُنقل كل شيء عبر `FileManager.trashItem(at:)`، لذا يمكنك استعادته.
- **طبقات الحماية.** `allowed` (ذاكرات التخزين المؤقت/السجلّات/المؤقت) ← `requiresReview` (الشيفرة المصدرية والتخزين السحابي والتنزيلات وبيانات التطوير) ← `blocked` (جذر النظام وبيانات التطبيقات وMail/Messages/Safari وبيانات المتصفح وKeychain).
- **Full Disk Access** اختياري لكنه موصى به حتى تتمكن عمليات الفحص من رؤية مواقع Library المحمية. يرشدك CleanMac خلال منحها من System Settings.

## التثبيت

### التنزيل (موصى به)

1. احصل على أحدث **`CleanMac.dmg`** من [صفحة الإصدارات](https://github.com/lgqyhm2010/CleanMac/releases/latest).
2. افتح ملف DMG واسحب **CleanMac** إلى **Applications**.

> **التشغيل الأول:** إذا قال macOS إنه لا يمكن التحقق من التطبيق (Gatekeeper) في إصدار لم يُوثَّق بعد، فانقر بزر الفأرة الأيمن على التطبيق ← **Open**، أو نفّذ:
> ```bash
> xattr -dr com.apple.quarantine /Applications/CleanMac.app
> ```
> تُفتح الإصدارات الموثَّقة رسميًا بنقر مزدوج عادي.

### المتطلبات

- macOS **14.0 (Sonoma)** أو أحدث
- Apple Silicon أو Intel

## البناء من المصدر

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

**سلسلة الأدوات:** Swift 6.0 (Xcode 16+). تُصدِّر الحزمة هدفًا تنفيذيًا `CleanMac` (التطبيق) وهدف مكتبة `CleanMacCore` (المنطق والنماذج والخدمات — يُبقى منفصلًا لقابلية الاختبار).

## تحزيم ملف DMG

يبني سكربت واحد التطبيق ويحزّم ملف DMG قابلًا للتوزيع وللتثبيت بالسحب:

```bash
./script/build_dmg.sh          # -> dist/CleanMac.dmg
```

يقوم السكربت بـ**التوقيع والتوثيق** عند توفر بيانات اعتماد Developer ID، و**يتراجع بلطف** (توقيع ad-hoc) خلاف ذلك، بحيث يُنتج ملف DMG دائمًا. اضبط التوقيع عبر متغيرات البيئة — ولا تُثبَّت أي أسرار في الشيفرة مطلقًا:

| المتغير | الغرض |
|----------|---------|
| `CODESIGN_IDENTITY` | هوية التوقيع، مثل `Developer ID Application: Name (TEAMID)`. تُكتشف تلقائيًا إذا لم تُضبط. |
| `NOTARY_PROFILE` | اسم ملف تعريف keychain لأداة `notarytool` (انظر [`docs/RELEASING.md`](docs/RELEASING.md)). |
| `APPLE_ID` / `APPLE_TEAM_ID` / `APPLE_APP_PASSWORD` | بيانات اعتماد توثيق بديلة (تستخدمها CI). |

> يتطلب التوزيع الحقيقي بأسلوب "التنزيل والفتح" شهادة **Apple Developer ID Application** مدفوعة. انظر [`docs/RELEASING.md`](docs/RELEASING.md) للإعداد لمرة واحدة. بدونها، يُبنى ملف DMG أيضًا لكنه غير موثَّق.

يُعاد بناء ملف DMG ونشره تلقائيًا مع كل دفعة إلى `main` ومع كل وسم عبر GitHub Actions ([`.github/workflows/release-dmg.yml`](.github/workflows/release-dmg.yml)).

## الترجمة والتوطين

يأتي CleanMac بـ**11 لغة**: الإنجليزية والصينية المبسّطة والصينية التقليدية واليابانية والإسبانية والفرنسية والعربية والهندية والبرتغالية (البرازيل) والروسية والبنغالية. تتبع الواجهة لغة نظامك افتراضيًا ويمكن تجاوزها من **Settings**.

تُقيم النصوص في `Sources/CleanMacCore/Resources/<locale>.lproj/Localizable.strings` خلف تجريد `L10n`. لإضافة لغة، أضِف مجلد `.lproj` جديدًا يحتوي على ملف `Localizable.strings` مترجَم، وأضِف الحالة إلى `AppLanguage`، ثم أعِد البناء.

## بنية المشروع

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

## المساهمة

المساهمات مُرحَّب بها! يرجى قراءة [CONTRIBUTING.md](CONTRIBUTING.md) لمعرفة كيفية البناء والاختبار وفتح طلب سحب. تحظى تصحيحات الترجمة واللغات الجديدة بتقدير خاص.

## الترخيص

يُصدَر CleanMac بموجب [رخصة MIT](LICENSE).
