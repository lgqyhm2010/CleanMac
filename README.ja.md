<div align="center">

<img src="Sources/CleanMac/Resources/Images/cleanmac-mascot.png" alt="CleanMac" width="160" />

# CleanMac

**macOS 向けの、ネイティブでプライベートな、AI 支援のディスククリーナー。**

キャッシュ、ログ、重複ファイル、大きなファイル、使っていないアプリをスキャンし、インストール済み AI CLI で匿名化メタデータをレビューして、安全に Trash へ移動します。CleanMac はアカウント不要でテレメトリもありませんが、AI CLI はプロバイダーのネットワークサービスを使う場合があります。

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS%2014%2B-black.svg)](#requirements)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Download](https://img.shields.io/badge/Download-.dmg-blue.svg)](https://github.com/lgqyhm2010/CleanMac/releases/latest)

[English](README.md) ·
[简体中文](README.zh-Hans.md) ·
[繁體中文](README.zh-Hant.md) ·
**日本語** ·
[Español](README.es.md) ·
[Français](README.fr.md) ·
[العربية](README.ar.md) ·
[हिन्दी](README.hi.md) ·
[Português (BR)](README.pt-BR.md) ·
[Русский](README.ru.md) ·
[বাংলা](README.bn.md)

</div>

---

## CleanMac とは？

CleanMac は、ディスク領域を**安全に**取り戻すネイティブな macOS アプリ（SwiftUI）です。Mac をスキャンしてクリーンアップ候補（キャッシュ、ログ、一時ファイル、重複ファイル、サイズの大きすぎるファイル、アプリの残存データ）を見つけ、それぞれにリスクレベルを割り当て、何かに触れる前にすべてを確認できるようにします。ファイルは **Trash** に移動され、いきなり完全に削除されることはありません。

他と違う点は、選択項目の**上限付き匿名化メタデータ**をインストール済み AI CLI（Claude Code、Codex、または Gemini CLI）に渡して、何を安全に削除できるかについてのセカンドオピニオンを得られることです。入力した質問はそのまま送信されます。CleanMac はファイル内容やフルパスを追加しませんが、CLI は設定済みプロバイダーへ接続する場合があります。

## 機能

- 🧹 **スマートスキャン** — キャッシュ、ログ、一時ファイル、Trash、開発者向けのゴミ（Xcode の派生データ）、ダウンロード、未分類の「その他」ファイル。
- 📦 **重複ファイル検出** — SHA-256 のコンテンツハッシュでファイルをグループ化し、最新のコピーを残します。
- 🐘 **大きなファイル** — 設定可能なしきい値（デフォルト 500 MB）を超えるファイルを洗い出します。
- 🗑️ **アプリのアンインストーラー** — 選択したアプリ本体をゴミ箱へ移動します。誤削除を防ぐため、ユーザーのサポートデータは変更しません。
- 🤖 **AI レビュー（ローカル）** — インストール済みの AI CLI に、候補を*安全に削除可能*、*リスクあり*、*要確認*に分類するよう依頼します。
- 🛡️ **安全第一** — 20 を超える安全ルールと 3 段階の保護ティアが、システム、Mail／Messages／Safari、Keychain のデータを削除からブロックします。
- 🌍 **11 言語** — システム言語または手動設定に従う、完全にローカライズされた UI。
- 🔒 **明確なプライバシー境界** — CleanMac のテレメトリやアカウントはなく、AI への受け渡しは匿名化して明示します。

## AI レビュー（ローカル）

CleanMac は、`PATH` 上のサポート対象コマンドライン AI ツール（Homebrew、npm、asdf、volta の一般的な場所を含む）を検出し、最大 80 件の候補をレビューするツールを選べるようにします。質問と構造化された匿名メタデータ（項目 ID、サイズ、更新日、カテゴリ、リスク、ルール ID）を送り、一意の空の一時ディレクトリから 120 秒のタイムアウト付きで CLI を実行し、すべての項目が一度ずつ分類された場合だけ返答を受け入れます。

| ツール | バイナリ | 選択できるモデル |
|------|--------|---------------------|
| **Claude Code** | `claude` | Default · Fable · Opus · Sonnet · Haiku |
| **Codex** | `codex` | Default · gpt-5.5 · gpt-5.4 · gpt-5.4-mini |
| **Gemini CLI** | `gemini` | Default · Pro · Flash |

候補リストとあなたのプロンプトは、サブプロセスとして stdin／引数経由で CLI に渡されます — **それらがあなたのマシンから出ることはありません**。CleanMac は、CLI がネストされたセッションを誤検出しないよう、子環境から自身のセッションマーカーも取り除きます。

## プライバシーと安全性

- **AI ネットワーク開示。** CleanMac 自体にテレメトリはありませんが、インストール済み AI CLI は設定されたプロバイダーへ接続する場合があります。質問はそのまま送信され、匿名 ID と上限付きメタデータが付加されます。ファイル内容や自動収集されたフルパスは送信されません。
- **`rm` ではなく Trash。** すべては `FileManager.trashItem(at:)` 経由で移動されるため、復元できます。
- **保護ティア。** `allowed`（キャッシュ／ログ／一時ファイル） → `requiresReview`（ソースコード、クラウドストレージ、ダウンロード、開発データ） → `blocked`（システムルート、アプリデータ、Mail／Messages／Safari、ブラウザデータ、Keychain）。
- **Full Disk Access** は任意ですが、保護された Library の場所をスキャンで参照できるように推奨されます。CleanMac は、システム設定でこれを許可する手順を案内します。

## インストール

### ダウンロード（推奨）

1. [Releases ページ](https://github.com/lgqyhm2010/CleanMac/releases/latest)から最新の **`CleanMac.dmg`** を入手します。
2. DMG を開き、**CleanMac** を **Applications** にドラッグします。

> **初回起動：** まだ公証されていないビルドで、macOS がアプリを検証できない（Gatekeeper）と表示する場合は、アプリを右クリック → **開く** を選ぶか、次を実行します：
> ```bash
> xattr -dr com.apple.quarantine /Applications/CleanMac.app
> ```
> 正式に公証されたリリースは、通常のダブルクリックで開きます。

### 動作要件

- macOS **14.0（Sonoma）** 以降
- Apple Silicon または Intel

## ソースからのビルド

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

**ツールチェーン：** Swift 6.0（Xcode 16 以降）。パッケージは実行可能ターゲット `CleanMac`（アプリ）とライブラリターゲット `CleanMacCore`（ロジック、モデル、サービス — テスト容易性のために分離）を公開しています。

## DMG のパッケージング

1 つのスクリプトでアプリをビルドし、配布可能なドラッグ＆ドロップでインストールできる DMG をパッケージングします：

```bash
./script/build_dmg.sh          # -> dist/CleanMac.dmg
```

このスクリプトは、Developer ID の資格情報が利用可能な場合は**署名と公証を行い**、そうでない場合は**優雅にデグレード**（アドホック署名）するため、常に DMG を生成します。署名は環境変数で設定します — シークレットがハードコードされることは一切ありません：

| 変数 | 目的 |
|----------|---------|
| `CODESIGN_IDENTITY` | 署名アイデンティティ。例：`Developer ID Application: Name (TEAMID)`。未設定の場合は自動検出されます。 |
| `NOTARY_PROFILE` | `notarytool` の keychain プロファイル名（[`docs/RELEASING.md`](docs/RELEASING.md) を参照）。 |
| `APPLE_ID` / `APPLE_TEAM_ID` / `APPLE_APP_PASSWORD` | 代替の公証用資格情報（CI で使用）。 |

> 本当の「ダウンロードして開く」形式の配布には、有料の **Apple Developer ID Application** 証明書が必要です。一度きりのセットアップについては [`docs/RELEASING.md`](docs/RELEASING.md) を参照してください。証明書がなくても DMG はビルドされますが、公証はされません。

`main` へのすべてのプッシュとすべてのタグは、GitHub Actions（[`.github/workflows/release-dmg.yml`](.github/workflows/release-dmg.yml)）を通じて自動的に DMG を再ビルドして公開します。

## ローカライゼーション

CleanMac は **11 言語** に対応しています：英語、簡体字中国語、繁体字中国語、日本語、スペイン語、フランス語、アラビア語、ヒンディー語、ポルトガル語（ブラジル）、ロシア語、ベンガル語。UI はデフォルトでシステム言語に従い、**設定** で上書きできます。

文字列は `L10n` 抽象化の背後にある `Sources/CleanMacCore/Resources/<locale>.lproj/Localizable.strings` に格納されています。言語を追加するには、翻訳した `Localizable.strings` を含む新しい `.lproj` フォルダを追加し、`AppLanguage` にそのケースを追加して、再ビルドします。

## プロジェクト構成

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

## コントリビュート

コントリビュートを歓迎します！ ビルド、テスト、プルリクエストの開き方については [CONTRIBUTING.md](CONTRIBUTING.md) をお読みください。翻訳の修正や新しいロケールの追加は特に歓迎します。

## ライセンス

CleanMac は [MIT License](LICENSE) の下で公開されています。
