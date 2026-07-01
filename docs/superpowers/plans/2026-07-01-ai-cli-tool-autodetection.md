# AI CLI Tool Auto-Detection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the AI Review page's two manual "executable" / "arguments" text fields with auto-detected AI CLI tools (codex, claude, gemini) presented as click-to-select pill buttons — no free-text configuration.

**Architecture:** `CleanMacCore` gains an `AIToolDetector` that resolves a fixed table of known-tool profiles (binary name, fixed arguments, and how each tool wants its prompt — stdin vs. an appended argument) against `$PATH`. `AIReviewService` is refactored to build its `Process` invocation from a `DetectedAITool` instead of a raw executable+arguments pair, branching on that tool's prompt-delivery mode. `CleaningStore` owns detection/selection state (re-detects every time the AI Review page appears, and once more defensively before running, so the existing ⌘⇧I menu shortcut works even if that page was never opened) and persists the user's last pick. `AIReviewView` replaces its two text fields with a row of pill buttons for whichever tools were actually found.

**Tech Stack:** Swift 6, SwiftPM, XCTest, Foundation `Process`/`FileManager`, SwiftUI for macOS.

## Global Constraints

- No manual executable/arguments text entry anywhere in the app (Settings' AI CLI panel and the AI Review page's two text fields are both removed, not just hidden).
- Known tools are a fixed, hardcoded list: **codex**, **claude** (Claude Code), **gemini** (Gemini CLI). No user-added custom entry (per explicit user decision during brainstorming).
- Tool detection re-runs every time the AI Review page appears and once more inside `askAI()` right before running — no caching, no manual "refresh" button (`which`-style lookups are near-instant).
- `codex exec` and `claude -p` read the prompt from stdin; `gemini -p` requires the prompt as the flag's argument value (confirmed via each CLI's own `--help` output) — this is a hard constraint on `AIReviewService`'s design, not a detail to skip.
- All new/changed user-facing strings must be present in all 11 `Localizable.strings` files (ar, bn, en, es, fr, hi, ja, pt-BR, ru, zh-Hans, zh-Hant) — this project ships 11 languages and has tests enforcing per-language key coverage.
- Dead code caused directly by this refactor (the old `CommandLineArguments` shell-arg parser, the `.executable`/`.arguments`/`.aiCLI` localization keys) must be deleted, not left orphaned.

---

## File Structure

- Create: `Sources/CleanMacCore/Services/AIToolDetector.swift`
- Create: `Tests/CleanMacCoreTests/AIToolDetectorTests.swift`
- Modify: `Sources/CleanMacCore/Services/AIReviewService.swift`
- Modify: `Tests/CleanMacCoreTests/AIReviewServiceTests.swift`
- Modify: `Sources/CleanMacCore/Localization/AppLanguage.swift`
- Modify: `Sources/CleanMacCore/Localization/L10n.swift`
- Modify: `Sources/CleanMacCore/Resources/*.lproj/Localizable.strings` (all 11)
- Modify: `Tests/CleanMacCoreTests/LocalizationTests.swift`
- Modify: `Sources/CleanMac/Stores/CleaningStore.swift`
- Create: `Tests/CleanMacUITests/CleaningStoreAIToolSelectionTests.swift`
- Delete: `Sources/CleanMac/Support/CommandLineArguments.swift`
- Delete: `Tests/CleanMacUITests/CommandLineArgumentsTests.swift`
- Modify: `Sources/CleanMac/Views/AIReviewView.swift`
- Modify: `Sources/CleanMac/Views/ContentView.swift`
- Modify: `Sources/CleanMac/Views/SettingsView.swift`
- Modify: `Sources/CleanMac/App/CleanMacApp.swift`
- Modify: `Tests/CleanMacUITests/ViewStateRenderingTests.swift`

---

### Task 1: AI tool detection service

**Files:**
- Create: `Tests/CleanMacCoreTests/AIToolDetectorTests.swift`
- Create: `Sources/CleanMacCore/Services/AIToolDetector.swift`

**Interfaces:**
- Produces (used by Task 2 and Task 4): `public struct AIToolProfile` with `id: String`, `displayName: String`, `binaryName: String`, `arguments: [String]`, `promptDelivery: AIToolProfile.PromptDelivery` (`.standardInput` or `.argument`), and `static let knownProfiles: [AIToolProfile]`. `public struct DetectedAITool: Identifiable` with `profile: AIToolProfile`, `executablePath: String`. `public protocol ExecutableLocating` with `func locate(_ binaryName: String) -> String?`. `public struct AIToolDetector` with `init(locator: ExecutableLocating = PATHExecutableLocator())` and `func detectAvailableTools(from profiles: [AIToolProfile] = AIToolProfile.knownProfiles) -> [DetectedAITool]`.

- [ ] **Step 1: Write the failing detector tests**

```swift
// Tests/CleanMacCoreTests/AIToolDetectorTests.swift
import XCTest
@testable import CleanMacCore

final class AIToolDetectorTests: XCTestCase {
    func testDetectsOnlyToolsWhoseBinaryIsFound() {
        let locator = FakeExecutableLocator(found: ["codex": "/opt/homebrew/bin/codex"])
        let detector = AIToolDetector(locator: locator)

        let detected = detector.detectAvailableTools()

        XCTAssertEqual(detected.map(\.id), ["codex"])
        XCTAssertEqual(detected.first?.executablePath, "/opt/homebrew/bin/codex")
    }

    func testDetectsMultipleToolsInProfileOrder() {
        let locator = FakeExecutableLocator(found: [
            "codex": "/opt/homebrew/bin/codex",
            "gemini": "/opt/homebrew/bin/gemini"
        ])
        let detector = AIToolDetector(locator: locator)

        XCTAssertEqual(detector.detectAvailableTools().map(\.id), ["codex", "gemini"])
    }

    func testReturnsEmptyWhenNoKnownToolIsFound() {
        let detector = AIToolDetector(locator: FakeExecutableLocator(found: [:]))

        XCTAssertTrue(detector.detectAvailableTools().isEmpty)
    }

    func testKnownProfilesUseCorrectPromptDeliveryPerTool() {
        let profiles = Dictionary(uniqueKeysWithValues: AIToolProfile.knownProfiles.map { ($0.id, $0) })

        XCTAssertEqual(profiles["codex"]?.promptDelivery, .standardInput)
        XCTAssertEqual(profiles["claude"]?.promptDelivery, .standardInput)
        XCTAssertEqual(profiles["gemini"]?.promptDelivery, .argument)
    }
}

private struct FakeExecutableLocator: ExecutableLocating {
    let found: [String: String]

    func locate(_ binaryName: String) -> String? {
        found[binaryName]
    }
}
```

- [ ] **Step 2: Run tests to verify they fail to compile (types don't exist yet)**

Run: `swift test --filter AIToolDetectorTests`
Expected: FAIL — `cannot find 'AIToolDetector' in scope` (or similar, since the type doesn't exist yet)

- [ ] **Step 3: Implement `AIToolDetector.swift`**

```swift
// Sources/CleanMacCore/Services/AIToolDetector.swift
import Foundation

public struct AIToolProfile: Identifiable, Equatable, Sendable {
    public enum PromptDelivery: Equatable, Sendable {
        case standardInput
        case argument
    }

    public let id: String
    public let displayName: String
    public let binaryName: String
    public let arguments: [String]
    public let promptDelivery: PromptDelivery

    public init(id: String, displayName: String, binaryName: String, arguments: [String], promptDelivery: PromptDelivery) {
        self.id = id
        self.displayName = displayName
        self.binaryName = binaryName
        self.arguments = arguments
        self.promptDelivery = promptDelivery
    }

    /// codex and claude read the prompt from stdin; gemini's `-p` requires the prompt as
    /// the flag's own argument value (confirmed via each CLI's `--help`).
    public static let knownProfiles: [AIToolProfile] = [
        AIToolProfile(id: "codex", displayName: "Codex", binaryName: "codex", arguments: ["exec"], promptDelivery: .standardInput),
        AIToolProfile(id: "claude", displayName: "Claude Code", binaryName: "claude", arguments: ["-p"], promptDelivery: .standardInput),
        AIToolProfile(id: "gemini", displayName: "Gemini CLI", binaryName: "gemini", arguments: ["-p"], promptDelivery: .argument)
    ]
}

public struct DetectedAITool: Identifiable, Equatable, Sendable {
    public var id: String { profile.id }
    public let profile: AIToolProfile
    public let executablePath: String

    public init(profile: AIToolProfile, executablePath: String) {
        self.profile = profile
        self.executablePath = executablePath
    }
}

public protocol ExecutableLocating: Sendable {
    func locate(_ binaryName: String) -> String?
}

/// `Process.executableURL` does not search `$PATH` — a bare binary name fails to launch.
/// This resolves a name to an absolute path the same way a shell would.
public struct PATHExecutableLocator: ExecutableLocating {
    public init() {}

    public func locate(_ binaryName: String) -> String? {
        guard let pathVariable = ProcessInfo.processInfo.environment["PATH"] else { return nil }
        for directory in pathVariable.split(separator: ":") {
            let candidatePath = URL(filePath: String(directory)).appending(path: binaryName).path
            if FileManager.default.isExecutableFile(atPath: candidatePath) {
                return candidatePath
            }
        }
        return nil
    }
}

public struct AIToolDetector {
    private let locator: ExecutableLocating

    public init(locator: ExecutableLocating = PATHExecutableLocator()) {
        self.locator = locator
    }

    public func detectAvailableTools(from profiles: [AIToolProfile] = AIToolProfile.knownProfiles) -> [DetectedAITool] {
        profiles.compactMap { profile in
            guard let executablePath = locator.locate(profile.binaryName) else { return nil }
            return DetectedAITool(profile: profile, executablePath: executablePath)
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --filter AIToolDetectorTests`
Expected: PASS — 4 tests, 0 failures

- [ ] **Step 5: Commit**

```bash
git add Sources/CleanMacCore/Services/AIToolDetector.swift Tests/CleanMacCoreTests/AIToolDetectorTests.swift
git commit -m "feat: add AI CLI tool auto-detection service"
```

---

### Task 2: Refactor `AIReviewService` to use a detected tool

**Files:**
- Modify: `Sources/CleanMacCore/Services/AIReviewService.swift`
- Modify: `Tests/CleanMacCoreTests/AIReviewServiceTests.swift`

**Interfaces:**
- Consumes: `AIToolProfile`, `DetectedAITool` from Task 1.
- Produces (used by Task 4): `AIReviewService.init(tool: DetectedAITool, runner: CommandRunning = ProcessCommandRunner())` (replaces the old `init(command: AICommand, runner:)`).

- [ ] **Step 1: Rewrite the test file for the new `tool:`-based init and both prompt-delivery modes**

```swift
// Tests/CleanMacCoreTests/AIReviewServiceTests.swift
import XCTest
@testable import CleanMacCore

final class AIReviewServiceTests: XCTestCase {
    func testPromptIncludesCandidateContextAndUserQuestion() {
        let service = AIReviewService(
            tool: DetectedAITool(
                profile: AIToolProfile(id: "test", displayName: "Test", binaryName: "test-ai", arguments: ["--quiet"], promptDelivery: .standardInput),
                executablePath: "/usr/bin/ai"
            ),
            runner: RecordingCommandRunner()
        )
        let prompt = service.makePrompt(
            candidates: [
                CleaningCandidate(
                    url: URL(filePath: "/Users/me/Downloads/old-installer.dmg"),
                    sizeBytes: 12_345,
                    modifiedAt: Date(timeIntervalSince1970: 1_700_000_000),
                    category: .downloads,
                    risk: .reviewRecommended,
                    reasons: ["Downloads folder item"],
                    isDirectory: false
                )
            ],
            userQuestion: "这个可以删吗？"
        )

        XCTAssertTrue(prompt.contains("old-installer.dmg"))
        XCTAssertTrue(prompt.contains("Downloads folder item"))
        XCTAssertTrue(prompt.contains("protection:"))
        XCTAssertTrue(prompt.contains("rules:"))
        XCTAssertTrue(prompt.contains("这个可以删吗？"))
        XCTAssertTrue(prompt.contains("JSON"))
    }

    func testReviewSendsPromptViaStandardInputWhenToolUsesStandardInputDelivery() async throws {
        let runner = RecordingCommandRunner()
        let tool = DetectedAITool(
            profile: AIToolProfile(id: "codex", displayName: "Codex", binaryName: "codex", arguments: ["exec"], promptDelivery: .standardInput),
            executablePath: "/usr/bin/ai"
        )
        let service = AIReviewService(tool: tool, runner: runner)
        let candidate = CleaningCandidate(
            url: URL(filePath: "/tmp/cache.bin"),
            sizeBytes: 64,
            modifiedAt: nil,
            category: .cache,
            risk: .usuallySafe,
            reasons: ["Cache file"],
            isDirectory: false
        )

        let review = try await service.review(candidates: [candidate], userQuestion: "safe?")

        XCTAssertEqual(review.output, "safe to remove")
        XCTAssertEqual(runner.commands, [AICommand(executable: "/usr/bin/ai", arguments: ["exec"])])
        XCTAssertEqual(runner.standardInputs.count, 1)
        XCTAssertTrue(runner.standardInputs[0].contains("/tmp/cache.bin"))
    }

    func testReviewAppendsPromptAsArgumentWhenToolUsesArgumentDelivery() async throws {
        let runner = RecordingCommandRunner()
        let tool = DetectedAITool(
            profile: AIToolProfile(id: "gemini", displayName: "Gemini CLI", binaryName: "gemini", arguments: ["-p"], promptDelivery: .argument),
            executablePath: "/usr/bin/ai"
        )
        let service = AIReviewService(tool: tool, runner: runner)
        let candidate = CleaningCandidate(
            url: URL(filePath: "/tmp/cache.bin"),
            sizeBytes: 64,
            modifiedAt: nil,
            category: .cache,
            risk: .usuallySafe,
            reasons: ["Cache file"],
            isDirectory: false
        )

        _ = try await service.review(candidates: [candidate], userQuestion: "safe?")

        XCTAssertEqual(runner.commands.count, 1)
        XCTAssertEqual(runner.commands[0].executable, "/usr/bin/ai")
        XCTAssertEqual(runner.commands[0].arguments.first, "-p")
        XCTAssertTrue(runner.commands[0].arguments.last?.contains("/tmp/cache.bin") ?? false)
        XCTAssertEqual(runner.standardInputs, [""])
    }

    func testReviewThrowsErrorDescribingWhyTheCommandFailed() async {
        let runner = FailingCommandRunner(
            exitCode: 1,
            standardError: "Error loading config.toml: unknown variant `default`, expected `fast` or `flex` in `service_tier`"
        )
        let tool = DetectedAITool(
            profile: AIToolProfile(id: "codex", displayName: "Codex", binaryName: "codex", arguments: ["exec"], promptDelivery: .standardInput),
            executablePath: "/usr/bin/env"
        )
        let service = AIReviewService(tool: tool, runner: runner)
        let candidate = CleaningCandidate(
            url: URL(filePath: "/tmp/cache.bin"),
            sizeBytes: 64,
            modifiedAt: nil,
            category: .cache,
            risk: .usuallySafe,
            reasons: ["Cache file"],
            isDirectory: false
        )

        do {
            _ = try await service.review(candidates: [candidate], userQuestion: "safe?")
            XCTFail("expected review to throw")
        } catch {
            let description = error.localizedDescription
            XCTAssertTrue(
                description.contains("service_tier"),
                "error shown to the user should include the AI command's actual stderr, got: \(description)"
            )
        }
    }
}

private final class RecordingCommandRunner: CommandRunning {
    private(set) var commands: [AICommand] = []
    private(set) var standardInputs: [String] = []

    func run(command: AICommand, standardInput: String) async throws -> CommandResult {
        commands.append(command)
        standardInputs.append(standardInput)
        return CommandResult(exitCode: 0, standardOutput: "safe to remove", standardError: "")
    }
}

private final class FailingCommandRunner: CommandRunning {
    private let exitCode: Int32
    private let standardError: String

    init(exitCode: Int32, standardError: String) {
        self.exitCode = exitCode
        self.standardError = standardError
    }

    func run(command: AICommand, standardInput: String) async throws -> CommandResult {
        CommandResult(exitCode: exitCode, standardOutput: "", standardError: standardError)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail to compile**

Run: `swift test --filter AIReviewServiceTests`
Expected: FAIL — `AIReviewService` has no member `init(tool:runner:)` (the old `init(command:runner:)` is still in place)

- [ ] **Step 3: Change `AIReviewService`'s init and `review()` to build the command from a `DetectedAITool`**

In `Sources/CleanMacCore/Services/AIReviewService.swift`, replace:

```swift
public final class AIReviewService {
    private let command: AICommand
    private let runner: CommandRunning

    public init(command: AICommand, runner: CommandRunning = ProcessCommandRunner()) {
        self.command = command
        self.runner = runner
    }
```

with:

```swift
public final class AIReviewService {
    private let tool: DetectedAITool
    private let runner: CommandRunning

    public init(tool: DetectedAITool, runner: CommandRunning = ProcessCommandRunner()) {
        self.tool = tool
        self.runner = runner
    }
```

Then replace the body of `review(candidates:userQuestion:)`:

```swift
    public func review(candidates: [CleaningCandidate], userQuestion: String) async throws -> AIReview {
        let prompt = makePrompt(candidates: candidates, userQuestion: userQuestion)
        let result = try await runner.run(command: command, standardInput: prompt)
        guard result.exitCode == 0 else {
            throw AIReviewError.commandFailed(
                exitCode: result.exitCode,
                standardError: result.standardError
            )
        }
        return AIReview(output: result.standardOutput, reviewedAt: Date())
    }
```

with:

```swift
    public func review(candidates: [CleaningCandidate], userQuestion: String) async throws -> AIReview {
        let prompt = makePrompt(candidates: candidates, userQuestion: userQuestion)
        let command: AICommand
        let standardInput: String
        switch tool.profile.promptDelivery {
        case .standardInput:
            command = AICommand(executable: tool.executablePath, arguments: tool.profile.arguments)
            standardInput = prompt
        case .argument:
            command = AICommand(executable: tool.executablePath, arguments: tool.profile.arguments + [prompt])
            standardInput = ""
        }
        let result = try await runner.run(command: command, standardInput: standardInput)
        guard result.exitCode == 0 else {
            throw AIReviewError.commandFailed(
                exitCode: result.exitCode,
                standardError: result.standardError
            )
        }
        return AIReview(output: result.standardOutput, reviewedAt: Date())
    }
```

`makePrompt(candidates:userQuestion:)`, `AIReviewError`, and `ProcessCommandRunner` stay exactly as-is — only the class's stored property and `review()`'s command construction change.

- [ ] **Step 4: Run tests to verify they pass**

Run: `swift test --filter AIReviewServiceTests`
Expected: PASS — 4 tests, 0 failures

- [ ] **Step 5: Run the full test suite to confirm nothing else references the old `init(command:)`**

Run: `swift build && swift test`
Expected: `Sources/CleanMac/Stores/CleaningStore.swift:305` (`AIReviewService(command: command)`) will fail to build here; that call site is intentionally fixed in Task 4, not this task. If Task 4 hasn't run yet, expect a build failure only at that one call site — confirm no other file breaks.

- [ ] **Step 6: Commit**

```bash
git add Sources/CleanMacCore/Services/AIReviewService.swift Tests/CleanMacCoreTests/AIReviewServiceTests.swift
git commit -m "refactor: build AIReviewService's command from a DetectedAITool"
```

---

### Task 3: Localization — rename/remove keys made obsolete by this feature

**Files:**
- Modify: `Sources/CleanMacCore/Localization/AppLanguage.swift`
- Modify: `Sources/CleanMacCore/Localization/L10n.swift`
- Modify: `Sources/CleanMacCore/Resources/ar.lproj/Localizable.strings`
- Modify: `Sources/CleanMacCore/Resources/bn.lproj/Localizable.strings`
- Modify: `Sources/CleanMacCore/Resources/en.lproj/Localizable.strings`
- Modify: `Sources/CleanMacCore/Resources/es.lproj/Localizable.strings`
- Modify: `Sources/CleanMacCore/Resources/fr.lproj/Localizable.strings`
- Modify: `Sources/CleanMacCore/Resources/hi.lproj/Localizable.strings`
- Modify: `Sources/CleanMacCore/Resources/ja.lproj/Localizable.strings`
- Modify: `Sources/CleanMacCore/Resources/pt-BR.lproj/Localizable.strings`
- Modify: `Sources/CleanMacCore/Resources/ru.lproj/Localizable.strings`
- Modify: `Sources/CleanMacCore/Resources/zh-Hans.lproj/Localizable.strings`
- Modify: `Sources/CleanMacCore/Resources/zh-Hant.lproj/Localizable.strings`
- Modify: `Tests/CleanMacCoreTests/LocalizationTests.swift`

**Interfaces:**
- Produces (used by Task 4 and Task 5): `CleaningErrorMessage.noAIToolDetected` (renamed from `.setAIExecutable`), `L10n.Key.aiTool` (renamed from `.command`). `L10n.Key.executable`, `.arguments`, `.aiCLI` no longer exist.

This task is three independent, mechanical renames applied together since they all touch the same 11 resource files. No app logic changes here — only enum case names and localized copy.

- [ ] **Step 1: Rename the error case in `CleaningErrorMessage`**

In `Sources/CleanMacCore/Localization/AppLanguage.swift`, replace:

```swift
public enum CleaningErrorMessage: Equatable, Sendable {
    case addFolderToScan
    case itemsCouldNotBeMoved(Int)
    case itemsWereProtected(Int)
    case selectItemForAIReview
    case setAIExecutable
    case system(String)
}
```

with:

```swift
public enum CleaningErrorMessage: Equatable, Sendable {
    case addFolderToScan
    case itemsCouldNotBeMoved(Int)
    case itemsWereProtected(Int)
    case selectItemForAIReview
    case noAIToolDetected
    case system(String)
}
```

- [ ] **Step 2: Update `L10n.error(_:language:)` and rename `.command` to `.aiTool`, remove `.executable`/`.arguments`/`.aiCLI` from `L10n.Key`**

In `Sources/CleanMacCore/Localization/L10n.swift`, in the `Key` enum, delete the line `case arguments` entirely (no replacement).

Replace:

```swift
        case command
```

with:

```swift
        case aiTool
```

Delete the line `case executable` entirely (no replacement).

Delete the line `case aiCLI` entirely (no replacement).

Then in `L10n.error(_:language:)`, replace:

```swift
        case .setAIExecutable:
            return localized("error.setAIExecutable", language: language)
```

with:

```swift
        case .noAIToolDetected:
            return localized("error.noAIToolDetected", language: language)
```

- [ ] **Step 3: Update all 11 `Localizable.strings` files**

For each file below: delete the `aiCLI`, `arguments`, and `executable` lines entirely; replace the `command` line with an `aiTool` line using the given text; replace the `error.setAIExecutable` line with `error.noAIToolDetected` using the given text.

| File | Delete these lines | Replace `"command" = "...";` with | Replace `"error.setAIExecutable" = "...";` with |
|---|---|---|---|
| `en.lproj` | `"aiCLI" = "AI CLI";` / `"arguments" = "Arguments";` / `"executable" = "Executable";` | `"aiTool" = "AI Tool";` | `"error.noAIToolDetected" = "No AI CLI tool found. Install codex, claude, or gemini.";` |
| `zh-Hans.lproj` | `"aiCLI" = "AI CLI";` / `"arguments" = "参数";` / `"executable" = "可执行文件";` | `"aiTool" = "AI 工具";` | `"error.noAIToolDetected" = "未检测到 AI CLI 工具，请安装 codex、claude 或 gemini。";` |
| `zh-Hant.lproj` | `"aiCLI" = "AI CLI";` / `"arguments" = "參數";` / `"executable" = "可執行檔";` | `"aiTool" = "AI 工具";` | `"error.noAIToolDetected" = "未偵測到 AI CLI 工具，請安裝 codex、claude 或 gemini。";` |
| `es.lproj` | `"aiCLI" = "AI CLI";` / `"arguments" = "Argumentos";` / `"executable" = "Ejecutable";` | `"aiTool" = "Herramienta de IA";` | `"error.noAIToolDetected" = "No se encontró ninguna herramienta de AI CLI. Instala codex, claude o gemini.";` |
| `ar.lproj` | `"aiCLI" = "AI CLI";` / `"arguments" = "الوسائط";` / `"executable" = "ملف تنفيذي";` | `"aiTool" = "أداة الذكاء الاصطناعي";` | `"error.noAIToolDetected" = "لم يتم العثور على أداة AI CLI. ثبّت codex أو claude أو gemini.";` |
| `bn.lproj` | `"aiCLI" = "AI CLI";` / `"arguments" = "আর্গুমেন্ট";` / `"executable" = "এক্সিকিউটেবল";` | `"aiTool" = "AI টুল";` | `"error.noAIToolDetected" = "কোনো AI CLI টুল পাওয়া যায়নি। codex, claude বা gemini ইনস্টল করুন।";` |
| `pt-BR.lproj` | `"aiCLI" = "AI CLI";` / `"arguments" = "Argumentos";` / `"executable" = "Executável";` | `"aiTool" = "Ferramenta de IA";` | `"error.noAIToolDetected" = "Nenhuma ferramenta de AI CLI encontrada. Instale o codex, claude ou gemini.";` |
| `fr.lproj` | `"aiCLI" = "AI CLI";` / `"arguments" = "Arguments";` / `"executable" = "Exécutable";` | `"aiTool" = "Outil IA";` | `"error.noAIToolDetected" = "Aucun outil AI CLI trouvé. Installez codex, claude ou gemini.";` |
| `hi.lproj` | `"aiCLI" = "AI CLI";` / `"arguments" = "आर्ग्युमेंट";` / `"executable" = "एक्जीक्यूटेबल";` | `"aiTool" = "AI टूल";` | `"error.noAIToolDetected" = "कोई AI CLI टूल नहीं मिला। codex, claude या gemini इंस्टॉल करें।";` |
| `ja.lproj` | `"aiCLI" = "AI CLI";` / `"arguments" = "引数";` / `"executable" = "実行ファイル";` | `"aiTool" = "AI ツール";` | `"error.noAIToolDetected" = "AI CLI ツールが見つかりません。codex、claude、gemini のいずれかをインストールしてください。";` |
| `ru.lproj` | `"aiCLI" = "AI CLI";` / `"arguments" = "Аргументы";` / `"executable" = "Исполняемый файл";` | `"aiTool" = "Инструмент ИИ";` | `"error.noAIToolDetected" = "Инструмент AI CLI не найден. Установите codex, claude или gemini.";` |

- [ ] **Step 4: Add the new key to the localization coverage test**

In `Tests/CleanMacCoreTests/LocalizationTests.swift`, in `localizableStringsResourcesCoverDynamicL10nKeys()`, add `"error.noAIToolDetected"` to the `dynamicKeys` set:

```swift
        let dynamicKeys = Set([
            "category.cache",
            "risk.beCareful",
            "protection.blocked",
            "permissionStatus.granted",
            "permission.fullDiskAccess.title",
            "permission.fullDiskAccess.instruction.1",
            "protectedItemCount",
            "moveToTrashSummary.protected",
            "scanReason.applicationBundle",
            "folderCount",
            "duplicateGroupDetail",
            "appUninstallPlanDetail",
            "status.candidatesFound",
            "status.movedToTrash",
            "error.itemsCouldNotBeMoved",
            "error.noAIToolDetected",
            "defaultAIQuestion",
            "storage.freeOfTotal",
            "windowTitle"
        ])
```

- [ ] **Step 5: Run the localization test suite**

Run: `swift test --filter LocalizationTests`
Expected: PASS — every locale file has `aiTool` and `error.noAIToolDetected`, and none still reference `command`/`executable`/`arguments`/`aiCLI`/`error.setAIExecutable` (those become build errors in Task 5 where the last Swift references get removed, not here).

- [ ] **Step 6: Commit**

```bash
git add Sources/CleanMacCore/Localization Sources/CleanMacCore/Resources Tests/CleanMacCoreTests/LocalizationTests.swift
git commit -m "refactor: rename AI CLI localization keys, drop the manual-config strings"
```

---

### Task 4: `CleaningStore` detection/selection state and `askAI()` rewrite

**Files:**
- Modify: `Sources/CleanMac/Stores/CleaningStore.swift`
- Create: `Tests/CleanMacUITests/CleaningStoreAIToolSelectionTests.swift`
- Delete: `Sources/CleanMac/Support/CommandLineArguments.swift`
- Delete: `Tests/CleanMacUITests/CommandLineArgumentsTests.swift`

**Interfaces:**
- Consumes: `AIToolDetector`, `AIToolProfile`, `DetectedAITool`, `ExecutableLocating` (Task 1); `AIReviewService.init(tool:runner:)` (Task 2); `CleaningErrorMessage.noAIToolDetected` (Task 3).
- Produces (used by Task 5): `CleaningStore.init(language:aiToolDetector:)` (new defaulted parameter), `@Published var detectedAITools: [DetectedAITool]`, `@Published var selectedAIToolID: String?`, `func refreshDetectedAITools()`, `func selectAITool(_ id: String)`, `func askAI()` (replaces `askAI(executable:argumentsText:)`).

- [ ] **Step 1: Write the failing `CleaningStore` tests**

```swift
// Tests/CleanMacUITests/CleaningStoreAIToolSelectionTests.swift
import CleanMacCore
import XCTest
@testable import CleanMac

@MainActor
final class CleaningStoreAIToolSelectionTests: XCTestCase {
    override func tearDown() {
        UserDefaults.standard.removeObject(forKey: "aiSelectedToolID")
        super.tearDown()
    }

    func testRefreshDetectedAIToolsAutoSelectsTheOnlyDetectedTool() {
        let store = makeStore(found: ["codex": "/opt/homebrew/bin/codex"])

        XCTAssertEqual(store.detectedAITools.map(\.id), ["codex"])
        XCTAssertEqual(store.selectedAIToolID, "codex")
    }

    func testRefreshDetectedAIToolsLeavesSelectionNilWhenMultipleFoundAndNoPriorChoice() {
        let store = makeStore(found: ["codex": "/a/codex", "claude": "/a/claude"])

        XCTAssertNil(store.selectedAIToolID)
    }

    func testSelectedToolPersistsAcrossAppRelaunch() {
        let first = makeStore(found: ["codex": "/a/codex", "claude": "/a/claude"])
        first.selectAITool("claude")

        let second = makeStore(found: ["codex": "/a/codex", "claude": "/a/claude"])

        XCTAssertEqual(second.selectedAIToolID, "claude")
    }

    func testAskAISetsNoAIToolDetectedErrorWhenNothingIsAvailable() {
        let store = makeStore(found: [:])
        store.candidates = [sampleCandidate()]
        store.selection.selectMovable(store.candidates)

        store.askAI()

        XCTAssertEqual(store.errorMessage, .noAIToolDetected)
    }

    private func makeStore(found: [String: String]) -> CleaningStore {
        CleaningStore(
            language: .english,
            aiToolDetector: AIToolDetector(locator: FakeExecutableLocator(found: found))
        )
    }

    private func sampleCandidate() -> CleaningCandidate {
        CleaningCandidate(
            url: URL(filePath: "/tmp/cache.bin"),
            sizeBytes: 64,
            modifiedAt: nil,
            category: .cache,
            risk: .usuallySafe,
            reasons: ["Cache file"],
            isDirectory: false
        )
    }
}

private struct FakeExecutableLocator: ExecutableLocating {
    let found: [String: String]

    func locate(_ binaryName: String) -> String? {
        found[binaryName]
    }
}
```

- [ ] **Step 2: Run tests to verify they fail to compile**

Run: `swift test --filter CleaningStoreAIToolSelectionTests`
Expected: FAIL — `CleaningStore` has no initializer accepting `aiToolDetector:`, no `detectedAITools`/`selectedAIToolID`/`selectAITool`, and `CleaningErrorMessage` has no `.noAIToolDetected` yet (that part depends on Task 3 already being done — this task assumes Tasks 1–3 are complete)

- [ ] **Step 3: Add detection/selection state to `CleaningStore`**

In `Sources/CleanMac/Stores/CleaningStore.swift`, add a stored detector and the new published properties. Replace:

```swift
@MainActor
final class CleaningStore: ObservableObject {
    @Published var roots: [URL] = DefaultScanRoots.urls {
        didSet { refreshVolumeSnapshot() }
    }
    @Published var appRoots: [URL] = DefaultApplicationRoots.urls
    @Published var candidates: [CleaningCandidate] = []
    @Published var selection = CleaningSelection()
    @Published var selectedCandidateID: CleaningCandidate.ID?
    @Published var lastReport: ScanReport?
    @Published var uninstallPlans: [AppUninstallPlan] = []
    @Published var cleanupResult: CleanupResult?
    @Published var aiQuestion: String
    @Published var aiOutput = ""
    @Published var status: CleaningStatus = .ready
    @Published var errorMessage: CleaningErrorMessage?
    @Published var isScanning = false
    @Published var isCleaning = false
    @Published var isReviewingWithAI = false
    @Published var isScanningApplications = false
    @Published var includeHiddenFiles = false
    @Published var minimumSizeMegabytes = 1.0
    @Published var largeFileThresholdMegabytes = 500.0
    @Published var volumeSnapshot: StorageVolumeSnapshot?

    init(language: ResolvedLanguage = AppLanguage.system.resolved()) {
        aiQuestion = L10n.defaultAIQuestion(language: language)
        refreshVolumeSnapshot()
    }
```

with:

```swift
@MainActor
final class CleaningStore: ObservableObject {
    @Published var roots: [URL] = DefaultScanRoots.urls {
        didSet { refreshVolumeSnapshot() }
    }
    @Published var appRoots: [URL] = DefaultApplicationRoots.urls
    @Published var candidates: [CleaningCandidate] = []
    @Published var selection = CleaningSelection()
    @Published var selectedCandidateID: CleaningCandidate.ID?
    @Published var lastReport: ScanReport?
    @Published var uninstallPlans: [AppUninstallPlan] = []
    @Published var cleanupResult: CleanupResult?
    @Published var aiQuestion: String
    @Published var aiOutput = ""
    @Published var status: CleaningStatus = .ready
    @Published var errorMessage: CleaningErrorMessage?
    @Published var isScanning = false
    @Published var isCleaning = false
    @Published var isReviewingWithAI = false
    @Published var isScanningApplications = false
    @Published var includeHiddenFiles = false
    @Published var minimumSizeMegabytes = 1.0
    @Published var largeFileThresholdMegabytes = 500.0
    @Published var volumeSnapshot: StorageVolumeSnapshot?
    @Published var detectedAITools: [DetectedAITool] = []
    @Published var selectedAIToolID: String?

    private let aiToolDetector: AIToolDetector
    private static let aiToolPreferenceKey = "aiSelectedToolID"

    init(language: ResolvedLanguage = AppLanguage.system.resolved(), aiToolDetector: AIToolDetector = AIToolDetector()) {
        self.aiToolDetector = aiToolDetector
        aiQuestion = L10n.defaultAIQuestion(language: language)
        refreshVolumeSnapshot()
        refreshDetectedAITools()
    }

    func refreshDetectedAITools() {
        detectedAITools = aiToolDetector.detectAvailableTools()

        if let selectedAIToolID, detectedAITools.contains(where: { $0.id == selectedAIToolID }) {
            return
        }

        let storedID = UserDefaults.standard.string(forKey: Self.aiToolPreferenceKey)
        if let storedID, detectedAITools.contains(where: { $0.id == storedID }) {
            selectedAIToolID = storedID
        } else if detectedAITools.count == 1 {
            selectedAIToolID = detectedAITools[0].id
        } else {
            selectedAIToolID = nil
        }
    }

    func selectAITool(_ id: String) {
        selectedAIToolID = id
        UserDefaults.standard.set(id, forKey: Self.aiToolPreferenceKey)
    }
```

- [ ] **Step 4: Replace `askAI(executable:argumentsText:)` with `askAI()`**

Replace:

```swift
    func askAI(executable: String, argumentsText: String) {
        let targets = selectedCandidates
        guard !targets.isEmpty else {
            errorMessage = .selectItemForAIReview
            return
        }
        guard !executable.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = .setAIExecutable
            return
        }
        guard !isReviewingWithAI else { return }

        isReviewingWithAI = true
        errorMessage = nil
        aiOutput = ""
        status = .askingAI

        let command = AICommand(
            executable: executable,
            arguments: CommandLineArguments.split(argumentsText)
        )
        let question = aiQuestion

        Task {
            do {
                let review = try await AIReviewService(command: command)
                    .review(candidates: targets, userQuestion: question)
                aiOutput = review.output
                status = .aiReviewFinished
            } catch {
                errorMessage = .system(error.localizedDescription)
                status = .aiReviewFailed
            }
            isReviewingWithAI = false
        }
    }
```

with:

```swift
    func askAI() {
        let targets = selectedCandidates
        guard !targets.isEmpty else {
            errorMessage = .selectItemForAIReview
            return
        }
        refreshDetectedAITools()
        guard let selectedAIToolID, let tool = detectedAITools.first(where: { $0.id == selectedAIToolID }) else {
            errorMessage = .noAIToolDetected
            return
        }
        guard !isReviewingWithAI else { return }

        isReviewingWithAI = true
        errorMessage = nil
        aiOutput = ""
        status = .askingAI

        let question = aiQuestion

        Task {
            do {
                let review = try await AIReviewService(tool: tool)
                    .review(candidates: targets, userQuestion: question)
                aiOutput = review.output
                status = .aiReviewFinished
            } catch {
                errorMessage = .system(error.localizedDescription)
                status = .aiReviewFailed
            }
            isReviewingWithAI = false
        }
    }
```

- [ ] **Step 5: Delete the now-dead `CommandLineArguments` parser and its tests**

```bash
rm Sources/CleanMac/Support/CommandLineArguments.swift
rm Tests/CleanMacUITests/CommandLineArgumentsTests.swift
```

- [ ] **Step 6: Run the new tests**

Run: `swift test --filter CleaningStoreAIToolSelectionTests`
Expected: PASS — 4 tests, 0 failures

Note: the app will not fully build yet — `AIReviewView.swift`, `ContentView.swift`, and `CleanMacApp.swift` still call the old `askAI(executable:argumentsText:)` signature and reference the removed `.executable`/`.arguments`/`.aiCLI` L10n keys. Those are fixed in Task 5. `swift test --filter` on a single class still requires the whole target to compile, so if this step fails to build because of those other call sites, treat that as expected until Task 5 lands — do not attempt to fix those files here.

- [ ] **Step 7: Commit**

```bash
git add Sources/CleanMac/Stores/CleaningStore.swift Tests/CleanMacUITests/CleaningStoreAIToolSelectionTests.swift
git rm Sources/CleanMac/Support/CommandLineArguments.swift Tests/CleanMacUITests/CommandLineArgumentsTests.swift
git commit -m "feat: detect and select AI CLI tools in CleaningStore"
```

---

### Task 5: UI — pill-button tool selection, wiring, and Settings cleanup

**Files:**
- Modify: `Sources/CleanMac/Views/AIReviewView.swift`
- Modify: `Sources/CleanMac/Views/ContentView.swift`
- Modify: `Sources/CleanMac/Views/SettingsView.swift`
- Modify: `Sources/CleanMac/App/CleanMacApp.swift`
- Modify: `Tests/CleanMacUITests/ViewStateRenderingTests.swift`

**Interfaces:**
- Consumes: `CleaningStore.detectedAITools`/`.selectedAIToolID`/`.selectAITool(_:)`/`.refreshDetectedAITools()`/`.askAI()` (Task 4), `L10n.Key.aiTool`, `CleaningErrorMessage.noAIToolDetected` (Task 3).

- [ ] **Step 1: Rewrite `AIReviewView.swift` — remove the manual fields, add the pill-button row**

Replace the entire contents of `Sources/CleanMac/Views/AIReviewView.swift` with:

```swift
import CleanMacCore
import SwiftUI

struct AIReviewView: View {
    @ObservedObject var store: CleaningStore
    var language: ResolvedLanguage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            CleanMacPageBackground(accent: CleanMacTheme.sectionTint(.aiReview))

            VStack(alignment: .leading, spacing: 14) {
                CleanMacHeroHeader(
                    title: L10n.text(.aiReview, language: language),
                    subtitle: "\(L10n.selectedHeadline(store.selectedSummary.selectedCount, language: language)) | \(Formatters.bytes(store.selectedSummary.totalBytes))",
                    symbolName: "sparkles",
                    asset: .aiReview,
                    tint: CleanMacTheme.sectionTint(.aiReview),
                    isActive: store.isReviewingWithAI
                ) {
                    Button {
                        store.askAI()
                    } label: {
                        Label(
                            store.isReviewingWithAI ? L10n.text(.reviewing, language: language) : L10n.text(.askAI, language: language),
                            systemImage: "sparkles"
                        )
                    }
                    .buttonStyle(CleanMacRaisedButtonStyle(tint: CleanMacTheme.sectionTint(.aiReview), prominent: true))
                    .disabled(store.selectedSummary.selectedCount == 0 || store.isReviewingWithAI || store.selectedAIToolID == nil)
                }

                if let error = store.errorMessage {
                    Text(L10n.error(error, language: language))
                        .font(.caption)
                        .foregroundStyle(CleanMacTheme.danger)
                }

                CleanMacPanel(tint: CleanMacTheme.sectionTint(.aiReview)) {
                    VStack(alignment: .leading, spacing: 12) {
                        CleanMacSectionHeader(
                            title: L10n.text(.aiTool, language: language),
                            symbolName: "terminal",
                            tint: CleanMacTheme.sectionTint(.aiReview)
                        )

                        if store.detectedAITools.isEmpty {
                            Text(L10n.error(.noAIToolDetected, language: language))
                                .font(.callout)
                                .foregroundStyle(CleanMacTheme.secondaryText)
                        } else {
                            HStack(spacing: 8) {
                                ForEach(store.detectedAITools) { tool in
                                    Button {
                                        store.selectAITool(tool.id)
                                    } label: {
                                        Text(tool.profile.displayName)
                                    }
                                    .buttonStyle(CleanMacRaisedButtonStyle(
                                        tint: CleanMacTheme.sectionTint(.aiReview),
                                        prominent: store.selectedAIToolID == tool.id
                                    ))
                                }
                            }
                        }

                        CleanMacSectionHeader(
                            title: L10n.text(.question, language: language),
                            symbolName: "text.bubble",
                            tint: CleanMacTheme.sectionTint(.aiReview)
                        )

                        TextEditor(text: $store.aiQuestion)
                            .font(.body)
                            .frame(minHeight: 86)
                            .scrollContentBackground(.hidden)
                            .background(CleanMacTheme.warmPane, in: CleanMacTheme.panelShape)
                            .overlay {
                                CleanMacTheme.panelShape
                                    .strokeBorder(CleanMacTheme.ink.opacity(0.28), lineWidth: 1.5)
                            }
                    }
                }

                CleanMacPanel(tint: CleanMacTheme.sectionTint(.aiReview)) {
                    aiOutputContent
                }
                .frame(maxHeight: .infinity)
            }
            .padding(16)
        }
        .foregroundStyle(CleanMacTheme.ink)
        .animation(CleanMacMotion.allowed(reduceMotion, CleanMacMotion.quick), value: store.isReviewingWithAI)
        .onAppear {
            store.refreshDetectedAITools()
        }
    }

    @ViewBuilder
    private var aiOutputContent: some View {
        if store.isReviewingWithAI {
            CleanMacProgressState(
                title: L10n.text(.reviewing, language: language),
                symbolName: "sparkles",
                asset: .aiReview,
                tint: CleanMacTheme.sectionTint(.aiReview)
            )
        } else if store.aiOutput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            CleanMacEmptyState(
                title: L10n.text(.noReview, language: language),
                symbolName: "sparkles",
                asset: .aiReview,
                tint: CleanMacTheme.sectionTint(.aiReview)
            )
        } else {
            TextEditor(text: $store.aiOutput)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .background(CleanMacTheme.warmPane, in: CleanMacTheme.panelShape)
                .transition(.opacity)
        }
    }
}
```

- [ ] **Step 2: Update `ContentView.swift` to stop passing the removed bindings**

In `Sources/CleanMac/Views/ContentView.swift`, replace:

```swift
    @AppStorage(AppLanguage.storageKey) private var appLanguageRaw = AppLanguage.system.rawValue
    @AppStorage("aiExecutable") private var aiExecutable = "/usr/bin/env"
    @AppStorage("aiArguments") private var aiArguments = "codex exec"
```

with:

```swift
    @AppStorage(AppLanguage.storageKey) private var appLanguageRaw = AppLanguage.system.rawValue
```

Replace:

```swift
                    case .aiReview:
                        AIReviewView(
                            store: store,
                            aiExecutable: $aiExecutable,
                            aiArguments: $aiArguments,
                            language: resolvedLanguage
                        )
```

with:

```swift
                    case .aiReview:
                        AIReviewView(
                            store: store,
                            language: resolvedLanguage
                        )
```

- [ ] **Step 3: Update `CleanMacApp.swift`'s menu-shortcut handler**

In `Sources/CleanMac/App/CleanMacApp.swift`, replace:

```swift
    @objc
    private func askAIFromMenu() {
        showMainWindow()
        let executable = UserDefaults.standard.string(forKey: "aiExecutable") ?? "/usr/bin/env"
        let arguments = UserDefaults.standard.string(forKey: "aiArguments") ?? "codex exec"
        store.askAI(executable: executable, argumentsText: arguments)
    }
```

with:

```swift
    @objc
    private func askAIFromMenu() {
        showMainWindow()
        store.askAI()
    }
```

- [ ] **Step 4: Remove the AI CLI panel from `SettingsView.swift`**

Replace the entire contents of `Sources/CleanMac/Views/SettingsView.swift` with:

```swift
import CleanMacCore
import SwiftUI

struct SettingsView: View {
    @AppStorage(AppLanguage.storageKey) private var appLanguageRaw = AppLanguage.system.rawValue

    var body: some View {
        CleanMacPage(accent: CleanMacTheme.purple) {
            CleanMacHeroHeader(
                title: L10n.text(.settings, language: resolvedLanguage),
                subtitle: L10n.text(.permissions, language: resolvedLanguage),
                symbolName: "gearshape",
                asset: .permissionShield,
                tint: CleanMacTheme.purple
            )

            CleanMacPanel(tint: CleanMacTheme.purple) {
                languageMenu
            }

            PermissionGuideView(
                guide: fullDiskAccessGuide,
                language: resolvedLanguage,
                displayStyle: .detailed
            )
        }
        .tint(CleanMacTheme.accent)
        .buttonStyle(CleanMacRaisedButtonStyle())
        .foregroundStyle(CleanMacTheme.ink)
    }

    @ViewBuilder
    private var languageMenu: some View {
        Menu {
            ForEach(AppLanguage.allCases) { preference in
                Button {
                    appLanguageRaw = preference.rawValue
                } label: {
                    if preference.rawValue == appLanguageRaw {
                        Label(
                            L10n.languagePreferenceName(preference, language: resolvedLanguage),
                            systemImage: "checkmark"
                        )
                    } else {
                        Text(L10n.languagePreferenceName(preference, language: resolvedLanguage))
                    }
                }
            }
        } label: {
            HStack(spacing: 10) {
                Text(L10n.text(.appLanguage, language: resolvedLanguage))
                    .foregroundStyle(CleanMacTheme.ink)

                Spacer(minLength: 12)

                Text(selectedLanguageName)
                    .foregroundStyle(CleanMacTheme.secondaryText)
                    .lineLimit(1)

                Image(systemName: "chevron.up.chevron.down")
                    .imageScale(.small)
            }
        }
        .buttonStyle(CleanMacRaisedButtonStyle(tint: CleanMacTheme.purple))
    }

    private var selectedLanguageName: String {
        let preference = AppLanguage(storedRawValue: appLanguageRaw)
        return L10n.languagePreferenceName(preference, language: resolvedLanguage)
    }

    private var resolvedLanguage: ResolvedLanguage {
        AppLanguage(storedRawValue: appLanguageRaw).resolved()
    }

    private var fullDiskAccessGuide: SystemPermissionGuide {
        .fullDiskAccess()
    }
}
```

- [ ] **Step 5: Run the full build to confirm every call site compiles**

Run: `swift build`
Expected: Build complete, no errors

- [ ] **Step 6: Update `ViewStateRenderingTests.swift` for the new pill UI**

In `Tests/CleanMacUITests/ViewStateRenderingTests.swift`, the existing `makeStoreWithCandidates` helper constructs `CleaningStore(language:)` with no detector override, so its rendered AI Review tests reflect whatever tools happen to be installed on the machine running the tests — harmless for the existing blank-vs-not-blank assertions, but add one deterministic test using an injected fake detector so the pill row itself is exercised. Add this test:

```swift
    func testAIReviewPageRendersToolSelectionPills() throws {
        let store = CleaningStore(
            language: .english,
            aiToolDetector: AIToolDetector(locator: FakeAIToolLocator(found: ["codex": "/opt/homebrew/bin/codex"]))
        )
        let candidates = sampleCandidates()
        store.candidates = candidates
        store.lastReport = ScanReport(
            candidates: candidates,
            duplicateGroups: [],
            totalBytes: candidates.reduce(0) { $0 + $1.sizeBytes },
            scannedFileCount: candidates.count,
            skippedFileCount: 0
        )
        store.selection.selectMovable(candidates)
        store.selectedCandidateID = candidates.first?.id
        store.status = .candidatesFound(candidates.count)

        let image = render(ContentView(store: store, initialSelection: .aiReview))
        try assertContentIsVisible(image, "AI review page rendered blank with a detected tool present")
    }
```

Add the fake locator as a new private type at the bottom of the file, alongside the existing `private func candidate(...)` helper:

```swift
private struct FakeAIToolLocator: ExecutableLocating {
    let found: [String: String]

    func locate(_ binaryName: String) -> String? {
        found[binaryName]
    }
}
```

- [ ] **Step 7: Run the full test suite**

Run: `swift build && swift test`
Expected: PASS — all XCTest and swift-testing suites green, no failures

- [ ] **Step 8: Manually verify in the running app**

Run: `./script/build_and_run.sh run`

Open the AI Review page and confirm: only actually-installed tools appear as pill buttons, the sole detected tool auto-selects, clicking a different pill switches the highlighted one, and with zero tools "found" (temporarily rename a test binary, or check on a machine without codex/claude/gemini) the empty-state hint text appears instead of a blank panel.

- [ ] **Step 9: Commit**

```bash
git add Sources/CleanMac/Views/AIReviewView.swift Sources/CleanMac/Views/ContentView.swift Sources/CleanMac/Views/SettingsView.swift Sources/CleanMac/App/CleanMacApp.swift Tests/CleanMacUITests/ViewStateRenderingTests.swift
git commit -m "feat: replace manual AI command fields with auto-detected tool pills"
```
