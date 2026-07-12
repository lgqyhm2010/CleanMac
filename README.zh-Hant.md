<div align="center">

<img src="Sources/CleanMac/Resources/Images/cleanmac-mascot.png" alt="CleanMac" width="160" />

# CleanMac

**專為 macOS 打造的原生、私密、AI 輔助磁碟清理工具。**

掃描快取、記錄檔、重複檔案、大型檔案與閒置應用程式——透過你已安裝的 AI CLI 檢閱去識別中繼資料——再安全地將它們移至 Trash。CleanMac 無需帳號且沒有遙測；AI CLI 可能使用其服務供應商的網路服務。

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS%2014%2B-black.svg)](#requirements)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Download](https://img.shields.io/badge/Download-.dmg-blue.svg)](https://github.com/lgqyhm2010/CleanMac/releases/latest)

[English](README.md) ·
[简体中文](README.zh-Hans.md) ·
**繁體中文** ·
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

## CleanMac 是什麼？

CleanMac 是一款原生的 macOS 應用程式（以 SwiftUI 打造），能**安全地**釋放磁碟空間。它會掃描你的 Mac，找出可清理的項目——快取、記錄檔、暫存檔、重複檔案、過大的檔案、殘留的應用程式資料——為每一項標記風險等級，並讓你在任何檔案被動到之前先行檢閱。檔案一律移至 **Trash**，絕不會直接永久刪除。

它與眾不同之處在於：它可以把所選項目的**有上限去識別中繼資料**交給你已安裝的 AI CLI（Claude Code、Codex 或 Gemini CLI），針對哪些項目可以安全移除提供第二意見。你輸入的問題會原樣傳送；CleanMac 不會額外加入檔案內容或完整路徑，而 CLI 可能連線至其服務供應商。

## 功能特色

- 🧹 **智慧掃描**——快取、記錄檔、暫存檔、Trash、開發者垃圾（Xcode derived data）、下載項目，以及未分類的「其他」檔案。
- 📦 **重複檔案搜尋**——依 SHA-256 內容雜湊將檔案分組，並保留最新的副本。
- 🐘 **大型檔案**——列出超過可設定門檻（預設 500 MB）的檔案。
- 🗑️ **應用程式解除安裝**——將選取的應用程式套件移到垃圾桶；為避免誤刪，使用者支援資料維持不變。
- 🤖 **AI 檢閱（本機）**——請已安裝的 AI CLI 將候選項目分類為*可安全刪除*、*有風險*與*需檢閱*。
- 🛡️ **安全至上**——20 多條安全規則與三層保護機制，阻止系統、Mail／Messages／Safari 以及 Keychain 資料被刪除。
- 🌍 **11 種語言**——完整在地化的介面，會依循你的系統語言，也可手動覆寫。
- 🔒 **明確的隱私邊界**——CleanMac 沒有遙測、無需帳號；AI 交接經過去識別並明確揭露。

## AI 檢閱（本機）

CleanMac 會偵測你 `PATH` 上受支援的命令列 AI 工具（包含常見的 Homebrew、npm、asdf 與 volta 路徑），讓你挑選其中一個來檢閱最多 80 個清理候選項目。應用程式會傳送你的問題與結構化匿名中繼資料（項目 ID、大小、修改日期、類別、風險及規則 ID），在唯一的空白暫存目錄執行 CLI，設定 120 秒逾時，且只有每個項目都恰好分類一次才接受回覆。

| 工具 | 執行檔 | 可選用的模型 |
|------|--------|---------------------|
| **Claude Code** | `claude` | Default · Fable · Opus · Sonnet · Haiku |
| **Codex** | `codex` | Default · gpt-5.5 · gpt-5.4 · gpt-5.4-mini |
| **Gemini CLI** | `gemini` | Default · Pro · Flash |

候選清單與你的提示會透過 stdin／引數以子行程方式傳給 CLI——**它們絕不會離開你的機器**。CleanMac 也會從子行程環境中移除自己的工作階段標記，以免 CLI 誤判為巢狀工作階段。

## 隱私與安全

- **AI 網路揭露。** CleanMac 本身沒有遙測，但已安裝的 AI CLI 可能連線至其服務供應商。AI 檢閱會原樣傳送你輸入的問題，並附上匿名 ID 與有上限的中繼資料；不會傳送檔案內容或自動收集的完整路徑。
- **移至 Trash，而非 `rm`。** 所有項目都透過 `FileManager.trashItem(at:)` 移動，因此你可以還原。
- **保護層級。** `allowed`（快取／記錄檔／暫存）→ `requiresReview`（原始碼、雲端儲存、下載項目、開發資料）→ `blocked`（系統根目錄、應用程式資料、Mail／Messages／Safari、瀏覽器資料、Keychain）。
- **Full Disk Access** 為選用但建議開啟，如此掃描才能看見受保護的 Library 位置。CleanMac 會引導你在系統設定中授予權限。

## 安裝

### 下載（建議）

1. 從 [Releases 頁面](https://github.com/lgqyhm2010/CleanMac/releases/latest) 取得最新的 **`CleanMac.dmg`**。
2. 開啟 DMG，並將 **CleanMac** 拖曳到 **Applications**。

> 官方下載均經過簽署與公證。若 Gatekeeper 無法驗證，請勿停用隔離保護；請刪除檔案並從官方 Releases 頁面重新下載。

### 系統需求

- macOS **14.0（Sonoma）** 或以上版本
- Apple Silicon 或 Intel

## 從原始碼建置

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

**工具鏈：** Swift 6.0（Xcode 16+）。此套件提供一個可執行目標 `CleanMac`（應用程式），以及一個函式庫目標 `CleanMacCore`（邏輯、模型、服務——為了可測試性而獨立分離）。

## 打包 DMG

單一指令碼即可建置通用雙架構應用程式，並打包成拖曳即安裝的 DMG：

```bash
# 僅供本機驗證、不可散布的預覽包
./script/build_dmg.sh --unsigned

# 正式發布；必須設定 Developer ID 與公證憑證
CLEANMAC_VERSION=1.0.0 CLEANMAC_BUILD_NUMBER=1 \
  NOTARY_PROFILE=CleanMacNotary ./script/build_dmg.sh --release
```

正式發布採失敗即停止：缺少憑證、版本或架構錯誤，以及簽署、公證、裝訂或 Gatekeeper 驗證失敗，都會終止建置。發布中繼資料與簽署由環境變數設定，密鑰不會寫死：

| 變數 | 用途 |
|----------|---------|
| `CODESIGN_IDENTITY` | 簽署身分，例如 `Developer ID Application: Name (TEAMID)`。若未設定會自動偵測。 |
| `CLEANMAC_VERSION` / `CLEANMAC_BUILD_NUMBER` | 發布版本與純數字建置編號。 |
| `NOTARY_PROFILE` | 一個 `notarytool` 鑰匙圈設定檔名稱（參見 [`docs/RELEASING.md`](docs/RELEASING.md)）。 |
| `APPLE_ID` / `APPLE_TEAM_ID` / `APPLE_APP_PASSWORD` | 替代的公證憑證（供 CI 使用）。 |

> `--unsigned` 僅供本機與 PR 驗證，絕不會作為正式版本發布。一次性設定請參見 [`docs/RELEASING.md`](docs/RELEASING.md)。

PR 與推送到 `main` 只執行唯讀的未簽署預覽建置；只有 `v*` 標籤可在正式包通過全部簽署與公證檢查後發布（[工作流程](.github/workflows/release-dmg.yml)）。

## 在地化

CleanMac 提供 **11 種語言**：英文、簡體中文、繁體中文、日文、西班牙文、法文、阿拉伯文、印地文、葡萄牙文（巴西）、俄文與孟加拉文。介面預設依循你的系統語言，並可在**設定**中覆寫。

字串位於 `Sources/CleanMacCore/Resources/<locale>.lproj/Localizable.strings`，透過 `L10n` 抽象層存取。若要新增語言，請加入一個新的 `.lproj` 資料夾並附上翻譯過的 `Localizable.strings`，將該案例加入 `AppLanguage`，再重新建置。

## 專案結構

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

## 參與貢獻

歡迎貢獻！關於如何建置、測試與開啟 pull request，請閱讀 [CONTRIBUTING.md](CONTRIBUTING.md)。我們特別感謝翻譯修正與新增語系。

## 授權

CleanMac 依 [MIT License](LICENSE) 釋出。
