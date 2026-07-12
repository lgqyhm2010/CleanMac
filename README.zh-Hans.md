<div align="center">

<img src="Sources/CleanMac/Resources/Images/cleanmac-mascot.png" alt="CleanMac" width="160" />

# CleanMac

**一款原生、私密、由 AI 辅助的 macOS 磁盘清理工具。**

扫描缓存、日志、重复文件、大文件和闲置应用 —— 用你已安装的 AI CLI 复核脱敏元数据 —— 然后安全地将其移入废纸篓。CleanMac 无需账户且不含遥测；AI CLI 可能使用其服务商的网络服务。

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-macOS%2014%2B-black.svg)](#requirements)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![Download](https://img.shields.io/badge/Download-.dmg-blue.svg)](https://github.com/lgqyhm2010/CleanMac/releases/latest)

[English](README.md) ·
**简体中文** ·
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

## CleanMac 是什么？

CleanMac 是一款原生 macOS 应用（SwiftUI），能**安全地**回收磁盘空间。它会扫描你的 Mac，找出可清理的对象 —— 缓存、日志、临时文件、重复文件、超大文件、残留的应用数据 —— 为每一项标注风险等级，并让你在任何操作发生之前逐一复核。文件会被移入**废纸篓**，绝不会直接永久删除。

它的与众不同之处在于：它可以把所选项目的**有上限脱敏元数据**交给你已安装的 AI CLI（Claude Code、Codex 或 Gemini CLI），就哪些内容可以安全移除征求第二意见。你输入的问题会原样发送；CleanMac 不会额外加入文件内容或完整路径，而 CLI 可能连接其配置的服务商。

## 功能特性

- 🧹 **智能扫描** —— 缓存、日志、临时文件、废纸篓、开发者垃圾（Xcode derived data）、下载内容，以及未归类的“其他”文件。
- 📦 **重复文件查找** —— 按 SHA-256 内容哈希将文件分组，并保留最新的副本。
- 🐘 **大文件** —— 列出超过可配置阈值（默认 500 MB）的文件。
- 🗑️ **应用卸载器** —— 将选中的应用包移到废纸篓；为避免误删，用户支持数据保持不变。
- 🤖 **AI 复核（本地）** —— 请已安装的 AI CLI 把候选项分类为*可安全删除*、*有风险*和*需要复核*。
- 🛡️ **安全优先** —— 20 多条安全规则和三级保护机制会阻止系统、邮件/信息/Safari 以及钥匙串数据被删除。
- 🌍 **11 种语言** —— 完全本地化的界面，会跟随你的系统语言，也可手动覆盖。
- 🔒 **明确的隐私边界** —— CleanMac 无遥测、无需账户；AI 交接经过脱敏并明确披露。

## AI 复核（本地）

CleanMac 会检测你 `PATH` 上受支持的命令行 AI 工具（包括常见的 Homebrew、npm、asdf 和 volta 位置），并让你选择其中之一来复核最多 80 个清理候选项。应用会发送你的问题和结构化匿名元数据（项目 ID、大小、修改日期、类别、风险及规则 ID），在唯一的空临时目录中运行 CLI，设置 120 秒超时，并且只有当每个项目都恰好分类一次时才接受回复。

| 工具 | 二进制文件 | 可选模型 |
|------|--------|---------------------|
| **Claude Code** | `claude` | Default · Fable · Opus · Sonnet · Haiku |
| **Codex** | `codex` | Default · gpt-5.5 · gpt-5.4 · gpt-5.4-mini |
| **Gemini CLI** | `gemini` | Default · Pro · Flash |

候选列表和你的提示会作为子进程通过 stdin/参数传给 CLI —— **它们绝不会离开你的机器**。CleanMac 还会从子进程环境中剥离它自己的会话标记，这样 CLI 就不会误判为嵌套会话。

## 隐私与安全

- **AI 网络披露。** CleanMac 本身不含遥测，但已安装的 AI CLI 可能连接其配置的服务商。AI 复核会原样发送你输入的问题，并附带匿名 ID 和有上限的元数据；不会发送文件内容或自动收集的完整路径。
- **废纸篓，而非 `rm`。** 所有内容都通过 `FileManager.trashItem(at:)` 移动，因此你可以恢复它们。
- **保护层级。** `allowed`（缓存/日志/临时文件）→ `requiresReview`（源代码、云存储、下载内容、开发数据）→ `blocked`（系统根目录、应用数据、邮件/信息/Safari、浏览器数据、钥匙串）。
- **完全磁盘访问权限（Full Disk Access）**是可选的，但推荐开启，这样扫描才能看到受保护的 Library 位置。CleanMac 会引导你在“系统设置”中授予该权限。

## 安装

### 下载（推荐）

1. 从[发布页](https://github.com/lgqyhm2010/CleanMac/releases/latest)获取最新的 **`CleanMac.dmg`**。
2. 打开 DMG，将 **CleanMac** 拖入**应用程序**文件夹。

> 官方下载均经过签名和公证。如果 Gatekeeper 无法验证，请不要关闭隔离保护；请删除文件，并从官方发布页重新下载。

### 系统要求

- macOS **14.0 (Sonoma)** 或更高版本
- Apple Silicon 或 Intel

## 从源码构建

```bash
git clone https://github.com/lgqyhm2010/CleanMac.git
cd CleanMac

# 构建并运行应用包（生成 dist/CleanMac.app 并启动它）
./script/build_and_run.sh

# 或仅用 SwiftPM 构建
swift build --product CleanMac

# 运行测试
swift test
```

**工具链：** Swift 6.0（Xcode 16+）。该 package 暴露了一个可执行目标 `CleanMac`（应用）和一个库目标 `CleanMacCore`（逻辑、模型、服务 —— 单独拆分以便于测试）。

## 打包 DMG

单个脚本即可构建通用双架构应用，并打包成拖拽即安装的 DMG：

```bash
# 仅供本地验证、不可分发的预览包
./script/build_dmg.sh --unsigned

# 正式发布；必须配置 Developer ID 和公证凭据
CLEANMAC_VERSION=1.0.0 CLEANMAC_BUILD_NUMBER=1 \
  NOTARY_PROFILE=CleanMacNotary ./script/build_dmg.sh --release
```

正式发布采用失败即停止：缺少凭据、版本或架构不正确，以及签名、公证、装订或 Gatekeeper 校验失败，都会终止构建。发布元数据和签名通过环境变量配置，任何密钥都不会被硬编码：

| 变量 | 用途 |
|----------|---------|
| `CODESIGN_IDENTITY` | 签名身份，例如 `Developer ID Application: Name (TEAMID)`。未设置时会自动检测。 |
| `CLEANMAC_VERSION` / `CLEANMAC_BUILD_NUMBER` | 发布版本号和纯数字构建号。 |
| `NOTARY_PROFILE` | 一个 `notarytool` 钥匙串配置文件名称（见 [`docs/RELEASING.md`](docs/RELEASING.md)）。 |
| `APPLE_ID` / `APPLE_TEAM_ID` / `APPLE_APP_PASSWORD` | 备用的公证凭据（供 CI 使用）。 |

> `--unsigned` 仅用于本地和 PR 验证，绝不会作为正式版本发布。一次性设置流程见 [`docs/RELEASING.md`](docs/RELEASING.md)。

PR 和推送到 `main` 只执行只读的未签名预览构建；只有 `v*` 标签能在正式包通过全部签名与公证校验后发布（[工作流](.github/workflows/release-dmg.yml)）。

## 本地化

CleanMac 提供 **11 种语言**：英语、简体中文、繁体中文、日语、西班牙语、法语、阿拉伯语、印地语、葡萄牙语（巴西）、俄语和孟加拉语。界面默认跟随你的系统语言，也可以在**设置**中覆盖。

字符串位于 `Sources/CleanMacCore/Resources/<locale>.lproj/Localizable.strings`，通过 `L10n` 抽象层访问。要添加一种语言，请新增一个包含已翻译 `Localizable.strings` 的 `.lproj` 文件夹，在 `AppLanguage` 中添加对应的 case，然后重新构建。

## 项目结构

```
Sources/
  CleanMac/          应用目标 —— SwiftUI 视图、store、AppKit 外壳、菜单
  CleanMacCore/      库目标 —— 模型、服务、安全规则、本地化
Tests/
  CleanMacCoreTests/ 核心逻辑测试
  CleanMacUITests/   应用/store 测试
script/
  build_and_run.sh   构建 .app 包并启动它
  build_dmg.sh       构建 + 打包（并签名/公证）一个 DMG
```

## 参与贡献

欢迎贡献！请阅读 [CONTRIBUTING.md](CONTRIBUTING.md) 了解如何构建、测试和提交 pull request。尤其欢迎翻译修正和新增语言。

## 许可证

CleanMac 基于 [MIT License](LICENSE) 发布。
