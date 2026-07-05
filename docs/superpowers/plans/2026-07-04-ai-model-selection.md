# AI Review Per-Tool Model Selection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the user pick a preset model per detected AI CLI (Claude Code / Codex / Gemini CLI) on the AI Review screen; "Default" passes no model flag.

**Architecture:** Extend `AIToolProfile` with `modelFlag` + `modelOptions` (curated presets), thread an optional `AIModelOption` through `AIReviewService.review`, persist per-tool selection in `CleaningStore` via UserDefaults (mirroring the tool-selection pattern), render a model pill row in `AIReviewView`.

**Tech Stack:** Swift 6 / SwiftUI / SPM, XCTest. Spec: `docs/superpowers/specs/2026-07-04-ai-model-selection-design.md`.

## Global Constraints

- All tests run with `swift test` from the repo root; full suite must stay green after every task.
- Localization: every new `L10n.Key` case needs a `"<key>" = "…";` line in ALL 11 `Sources/CleanMacCore/Resources/*.lproj/Localizable.strings` (ar, bn, en, es, fr, hi, ja, pt-BR, ru, zh-Hans, zh-Hant) — the existing coverage tests fail otherwise.
- Argument-order invariant: for `.standardInput` tools the model pair is appended AFTER `profile.arguments`; for `.argument` tools it is inserted BEFORE `profile.arguments` (gemini's prompt must directly follow `-p`).
- UserDefaults keys: tool selection uses `"aiSelectedToolID"` (existing); model selection uses `"aiModelPreferenceByTool"` (new, `[String: String]`).

---

### Task 1: `AIModelOption` presets on `AIToolProfile` (Core)

**Files:**
- Modify: `Sources/CleanMacCore/Services/AIToolDetector.swift` (AIToolProfile, lines 3–30)
- Test: `Tests/CleanMacCoreTests/AIToolDetectorTests.swift`

**Interfaces:**
- Produces: `AIModelOption { id: String, displayName: String, flagValue: String? }` (`Identifiable, Equatable, Sendable`), `AIModelOption.default`, `AIToolProfile.modelFlag: String`, `AIToolProfile.modelOptions: [AIModelOption]` (first entry is always `.default`). Existing `AIToolProfile.init` keeps compiling via defaulted parameters.

- [ ] **Step 1: Write the failing tests** — append to `AIToolDetectorTests.swift`:

```swift
func testKnownProfilesExposeDefaultFirstModelOptions() {
    for profile in AIToolProfile.knownProfiles {
        XCTAssertEqual(profile.modelOptions.first, .default, "\(profile.id) must offer Default first")
        XCTAssertGreaterThan(profile.modelOptions.count, 1, "\(profile.id) must offer real models")
    }
}

func testKnownProfilesUseEachCLIsModelFlag() {
    let flags = Dictionary(uniqueKeysWithValues: AIToolProfile.knownProfiles.map { ($0.id, $0.modelFlag) })
    XCTAssertEqual(flags["claude"], "--model")
    XCTAssertEqual(flags["codex"], "-m")
    XCTAssertEqual(flags["gemini"], "-m")
}

func testClaudeModelOptionsUseAliases() {
    let claude = AIToolProfile.knownProfiles.first { $0.id == "claude" }
    XCTAssertEqual(claude?.modelOptions.compactMap(\.flagValue), ["fable", "opus", "sonnet", "haiku"])
}
```

- [ ] **Step 2: Run to verify failure**

Run: `swift test --filter AIToolDetectorTests 2>&1 | tail -5`
Expected: compile error — `modelOptions`/`modelFlag`/`.default` do not exist.

- [ ] **Step 3: Implement** — in `AIToolDetector.swift`, above `AIToolProfile`:

```swift
public struct AIModelOption: Identifiable, Equatable, Sendable {
    public let id: String
    public let displayName: String
    /// nil = the CLI's own default model; no model flag is appended.
    public let flagValue: String?

    public init(id: String, displayName: String, flagValue: String?) {
        self.id = id
        self.displayName = displayName
        self.flagValue = flagValue
    }

    /// The view renders this entry with the localized "Default" label, keyed off `flagValue == nil`.
    public static let `default` = AIModelOption(id: "default", displayName: "Default", flagValue: nil)
}
```

Extend `AIToolProfile`: add stored properties and defaulted init parameters so existing call sites compile:

```swift
public let modelFlag: String
public let modelOptions: [AIModelOption]

public init(
    id: String, displayName: String, binaryName: String, arguments: [String],
    promptDelivery: PromptDelivery,
    modelFlag: String = "--model",
    modelOptions: [AIModelOption] = [.default]
) {
    self.id = id
    self.displayName = displayName
    self.binaryName = binaryName
    self.arguments = arguments
    self.promptDelivery = promptDelivery
    self.modelFlag = modelFlag
    self.modelOptions = modelOptions
}
```

Update `knownProfiles` (model lists are curated presets — no CLI can enumerate models):

```swift
public static let knownProfiles: [AIToolProfile] = [
    AIToolProfile(
        id: "codex", displayName: "Codex", binaryName: "codex",
        arguments: ["exec"], promptDelivery: .standardInput,
        modelFlag: "-m",
        modelOptions: [
            .default,
            AIModelOption(id: "gpt-5.1-codex", displayName: "gpt-5.1-codex", flagValue: "gpt-5.1-codex"),
            AIModelOption(id: "gpt-5.1-codex-mini", displayName: "gpt-5.1-codex-mini", flagValue: "gpt-5.1-codex-mini"),
            AIModelOption(id: "gpt-5.1", displayName: "gpt-5.1", flagValue: "gpt-5.1")
        ]
    ),
    AIToolProfile(
        id: "claude", displayName: "Claude Code", binaryName: "claude",
        arguments: ["-p"], promptDelivery: .standardInput,
        modelFlag: "--model",
        modelOptions: [
            .default,
            AIModelOption(id: "fable", displayName: "Fable", flagValue: "fable"),
            AIModelOption(id: "opus", displayName: "Opus", flagValue: "opus"),
            AIModelOption(id: "sonnet", displayName: "Sonnet", flagValue: "sonnet"),
            AIModelOption(id: "haiku", displayName: "Haiku", flagValue: "haiku")
        ]
    ),
    AIToolProfile(
        id: "gemini", displayName: "Gemini CLI", binaryName: "gemini",
        arguments: ["-p"], promptDelivery: .argument,
        modelFlag: "-m",
        modelOptions: [
            .default,
            AIModelOption(id: "gemini-2.5-pro", displayName: "gemini-2.5-pro", flagValue: "gemini-2.5-pro"),
            AIModelOption(id: "gemini-2.5-flash", displayName: "gemini-2.5-flash", flagValue: "gemini-2.5-flash")
        ]
    )
]
```

Keep the existing doc comment about prompt delivery above `knownProfiles`.

- [ ] **Step 4: Run to verify pass**

Run: `swift test --filter AIToolDetectorTests 2>&1 | tail -5`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add Sources/CleanMacCore/Services/AIToolDetector.swift Tests/CleanMacCoreTests/AIToolDetectorTests.swift
git commit -m "feat: add curated model presets to AI tool profiles"
```

---

### Task 2: `AIReviewService.review(model:)` argument assembly

**Files:**
- Modify: `Sources/CleanMacCore/Services/AIReviewService.swift` (the `review` method)
- Test: `Tests/CleanMacCoreTests/AIReviewServiceTests.swift`

**Interfaces:**
- Consumes: `AIModelOption` from Task 1.
- Produces: `public func review(candidates: [CleaningCandidate], userQuestion: String, model: AIModelOption? = nil) async throws -> AIReview`. Existing two-argument call sites keep compiling.

- [ ] **Step 1: Write the failing tests** — append to `AIReviewServiceTests.swift` (reuse the file's existing `RecordingCommandRunner`):

```swift
func testReviewAppendsModelFlagAfterBaseArgumentsForStdinTools() async throws {
    let runner = RecordingCommandRunner()
    let profile = AIToolProfile.knownProfiles.first { $0.id == "codex" }!
    let tool = DetectedAITool(profile: profile, executablePath: "/usr/bin/ai")
    let service = AIReviewService(tool: tool, runner: runner)
    let model = AIModelOption(id: "gpt-5.1", displayName: "gpt-5.1", flagValue: "gpt-5.1")

    _ = try await service.review(candidates: [sampleCandidate()], userQuestion: "safe?", model: model)

    XCTAssertEqual(runner.commands[0].arguments, ["exec", "-m", "gpt-5.1"])
}

func testReviewInsertsModelFlagBeforeBaseArgumentsForArgumentTools() async throws {
    // gemini's prompt must directly follow -p, so the model pair goes first: -m X -p <prompt>
    let runner = RecordingCommandRunner()
    let profile = AIToolProfile.knownProfiles.first { $0.id == "gemini" }!
    let tool = DetectedAITool(profile: profile, executablePath: "/usr/bin/ai")
    let service = AIReviewService(tool: tool, runner: runner)
    let model = AIModelOption(id: "gemini-2.5-pro", displayName: "gemini-2.5-pro", flagValue: "gemini-2.5-pro")

    _ = try await service.review(candidates: [sampleCandidate()], userQuestion: "safe?", model: model)

    let arguments = runner.commands[0].arguments
    XCTAssertEqual(Array(arguments.prefix(3)), ["-m", "gemini-2.5-pro", "-p"])
    XCTAssertTrue(arguments.last?.contains("safe?") ?? false)
}

func testReviewOmitsModelFlagForDefaultAndNilModel() async throws {
    let runner = RecordingCommandRunner()
    let profile = AIToolProfile.knownProfiles.first { $0.id == "claude" }!
    let tool = DetectedAITool(profile: profile, executablePath: "/usr/bin/ai")
    let service = AIReviewService(tool: tool, runner: runner)

    _ = try await service.review(candidates: [sampleCandidate()], userQuestion: "safe?", model: .default)
    _ = try await service.review(candidates: [sampleCandidate()], userQuestion: "safe?")

    XCTAssertEqual(runner.commands[0].arguments, ["-p"])
    XCTAssertEqual(runner.commands[1].arguments, ["-p"])
}
```

Add the shared helper once (file-private, below the test class, only if the file does not already define it):

```swift
private func sampleCandidate() -> CleaningCandidate {
    CleaningCandidate(
        url: URL(filePath: "/tmp/cache.bin"), sizeBytes: 64, modifiedAt: nil,
        category: .cache, risk: .usuallySafe, reasons: ["Cache file"], isDirectory: false
    )
}
```

(Existing tests build candidates inline; leave them untouched.)

- [ ] **Step 2: Run to verify failure**

Run: `swift test --filter AIReviewServiceTests 2>&1 | tail -5`
Expected: compile error — `review` has no `model:` parameter.

- [ ] **Step 3: Implement** — in `AIReviewService.review`, replace the command-construction `switch` with:

```swift
public func review(candidates: [CleaningCandidate], userQuestion: String, model: AIModelOption? = nil) async throws -> AIReview {
    let prompt = makePrompt(candidates: candidates, userQuestion: userQuestion)

    let environment = Self.childEnvironment(from: ProcessInfo.processInfo.environment)

    // The model pair's position depends on prompt delivery: gemini's prompt must
    // directly follow its "-p", so the pair goes before the base arguments there.
    let modelArguments = model?.flagValue.map { [tool.profile.modelFlag, $0] } ?? []

    let command: AICommand
    let standardInput: String
    switch tool.profile.promptDelivery {
    case .standardInput:
        command = AICommand(executable: tool.executablePath, arguments: tool.profile.arguments + modelArguments, environment: environment)
        standardInput = prompt
    case .argument:
        command = AICommand(executable: tool.executablePath, arguments: modelArguments + tool.profile.arguments + [prompt], environment: environment)
        standardInput = ""
    }
    let result = try await runner.run(command: command, standardInput: standardInput)
    guard result.exitCode == 0 else {
        throw AIReviewError.commandFailed(
            exitCode: result.exitCode,
            standardError: result.standardError,
            standardOutput: result.standardOutput
        )
    }
    return AIReview(output: result.standardOutput, reviewedAt: Date())
}
```

- [ ] **Step 4: Run to verify pass**

Run: `swift test --filter AIReviewServiceTests 2>&1 | tail -5`
Expected: all pass (including the pre-existing argument-delivery tests).

- [ ] **Step 5: Commit**

```bash
git add Sources/CleanMacCore/Services/AIReviewService.swift Tests/CleanMacCoreTests/AIReviewServiceTests.swift
git commit -m "feat: thread model selection into AI review command assembly"
```

---

### Task 3: Per-tool model selection state in `CleaningStore`

**Files:**
- Modify: `Sources/CleanMac/Stores/CleaningStore.swift` (properties near line 30, `askAI()` near line 325)
- Test: `Tests/CleanMacUITests/CleaningStoreAIToolSelectionTests.swift`

**Interfaces:**
- Consumes: `AIModelOption`, `AIToolProfile.modelOptions`, `review(model:)` from Tasks 1–2.
- Produces: `@Published var selectedModelIDsByTool: [String: String]`, `func selectModel(_ modelID: String, for toolID: String)`, `func selectedModelOption(for toolID: String) -> AIModelOption?`.

- [ ] **Step 1: Write the failing tests** — append to `CleaningStoreAIToolSelectionTests.swift`, and extend `tearDown`:

```swift
override func tearDown() {
    UserDefaults.standard.removeObject(forKey: "aiSelectedToolID")
    UserDefaults.standard.removeObject(forKey: "aiModelPreferenceByTool")
    super.tearDown()
}
```

```swift
func testSelectedModelDefaultsToTheFirstOptionAndFallsBackOnUnknownID() {
    let store = makeStore(found: ["claude": "/a/claude"])

    XCTAssertEqual(store.selectedModelOption(for: "claude"), .default)

    store.selectModel("no-such-model", for: "claude")
    XCTAssertEqual(store.selectedModelOption(for: "claude"), .default, "unknown ids fall back to Default")
}

func testSelectedModelPersistsPerToolAcrossRelaunch() {
    let first = makeStore(found: ["claude": "/a/claude", "codex": "/a/codex"])
    first.selectModel("opus", for: "claude")
    first.selectModel("gpt-5.1", for: "codex")

    let second = makeStore(found: ["claude": "/a/claude", "codex": "/a/codex"])

    XCTAssertEqual(second.selectedModelOption(for: "claude")?.id, "opus")
    XCTAssertEqual(second.selectedModelOption(for: "codex")?.id, "gpt-5.1")
}
```

- [ ] **Step 2: Run to verify failure**

Run: `swift test --filter CleaningStoreAIToolSelectionTests 2>&1 | tail -5`
Expected: compile error — `selectedModelOption`/`selectModel` do not exist.

- [ ] **Step 3: Implement** — in `CleaningStore`:

Add below `@Published var selectedAIToolID: String?` (line 30):

```swift
@Published var selectedModelIDsByTool: [String: String]
```

Add below `aiToolPreferenceKey` (line 33):

```swift
private static let aiModelPreferenceKey = "aiModelPreferenceByTool"
```

In `init`, before `refreshDetectedAITools()`:

```swift
selectedModelIDsByTool = UserDefaults.standard.dictionary(forKey: Self.aiModelPreferenceKey) as? [String: String] ?? [:]
```

Add below `selectAITool` (line 66):

```swift
func selectModel(_ modelID: String, for toolID: String) {
    selectedModelIDsByTool[toolID] = modelID
    UserDefaults.standard.set(selectedModelIDsByTool, forKey: Self.aiModelPreferenceKey)
}

/// Resolves the persisted choice against the tool's presets; unknown or missing
/// ids degrade to the first (Default) option so removed presets never break askAI.
func selectedModelOption(for toolID: String) -> AIModelOption? {
    guard let profile = detectedAITools.first(where: { $0.id == toolID })?.profile else { return nil }
    let storedID = selectedModelIDsByTool[toolID]
    return profile.modelOptions.first { $0.id == storedID } ?? profile.modelOptions.first
}
```

In `askAI()`, pass the model (replace the `review` call):

```swift
let model = selectedModelOption(for: tool.id)
Task {
    do {
        let review = try await AIReviewService(tool: tool)
            .review(candidates: targets, userQuestion: question, model: model)
```

- [ ] **Step 4: Run to verify pass**

Run: `swift test --filter CleaningStoreAIToolSelectionTests 2>&1 | tail -5`
Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add Sources/CleanMac/Stores/CleaningStore.swift Tests/CleanMacUITests/CleaningStoreAIToolSelectionTests.swift
git commit -m "feat: persist per-tool AI model selection in CleaningStore"
```

---

### Task 4: Model pill row in `AIReviewView` + localization

**Files:**
- Modify: `Sources/CleanMacCore/Localization/L10n.swift` (Key enum, lines 4–111)
- Modify: all 11 `Sources/CleanMacCore/Resources/<lang>.lproj/Localizable.strings`
- Modify: `Sources/CleanMac/Views/AIReviewView.swift` (tool-pill section, lines 55–74)

**Interfaces:**
- Consumes: `store.selectedModelOption(for:)`, `store.selectModel(_:for:)` from Task 3; `L10n.text(.model, …)`, `L10n.text(.defaultModel, …)`.
- Produces: user-visible model pills; two new `L10n.Key` cases: `model`, `defaultModel`.

- [ ] **Step 1: Add the L10n keys** — in `L10n.swift` Key enum, insert:

```swift
case defaultModel
case model
```

- [ ] **Step 2: Run the localization tests to see them fail**

Run: `swift test --filter Localization 2>&1 | tail -5`
Expected: FAIL — "Localizable.strings resources cover every static L10n key" reports the two missing keys per language.

- [ ] **Step 3: Add the strings** — append one line each (keep each file's existing ordering style) to every `Localizable.strings`:

| File | `"model"` | `"defaultModel"` |
|---|---|---|
| en.lproj | `"model" = "Model";` | `"defaultModel" = "Default";` |
| zh-Hans.lproj | `"model" = "模型";` | `"defaultModel" = "默认";` |
| zh-Hant.lproj | `"model" = "模型";` | `"defaultModel" = "預設";` |
| ja.lproj | `"model" = "モデル";` | `"defaultModel" = "デフォルト";` |
| es.lproj | `"model" = "Modelo";` | `"defaultModel" = "Predeterminado";` |
| fr.lproj | `"model" = "Modèle";` | `"defaultModel" = "Par défaut";` |
| ar.lproj | `"model" = "النموذج";` | `"defaultModel" = "افتراضي";` |
| hi.lproj | `"model" = "मॉडल";` | `"defaultModel" = "डिफ़ॉल्ट";` |
| pt-BR.lproj | `"model" = "Modelo";` | `"defaultModel" = "Padrão";` |
| ru.lproj | `"model" = "Модель";` | `"defaultModel" = "По умолчанию";` |
| bn.lproj | `"model" = "মডেল";` | `"defaultModel" = "ডিফল্ট";` |

- [ ] **Step 4: Run localization tests to verify pass**

Run: `swift test --filter Localization 2>&1 | tail -5`
Expected: PASS.

- [ ] **Step 5: Render the pills** — in `AIReviewView.swift`, directly after the tool-pill `HStack` closes (after line 73's `}` that ends `HStack(spacing: 8)`, still inside the `else` branch), add:

```swift
if let selectedTool = store.detectedAITools.first(where: { $0.id == store.selectedAIToolID }) {
    CleanMacSectionHeader(
        title: L10n.text(.model, language: language),
        symbolName: "cpu",
        tint: CleanMacTheme.sectionTint(.aiReview)
    )

    HStack(spacing: 8) {
        ForEach(selectedTool.profile.modelOptions) { option in
            Button {
                store.selectModel(option.id, for: selectedTool.id)
            } label: {
                Text(option.flagValue == nil ? L10n.text(.defaultModel, language: language) : option.displayName)
            }
            .buttonStyle(CleanMacRaisedButtonStyle(
                tint: CleanMacTheme.sectionTint(.aiReview),
                prominent: store.selectedModelOption(for: selectedTool.id)?.id == option.id
            ))
            .accessibilityAddTraits(store.selectedModelOption(for: selectedTool.id)?.id == option.id ? [.isSelected] : [])
        }
    }
}
```

- [ ] **Step 6: Full suite**

Run: `swift test 2>&1 | grep -E "Executed.*failure" | tail -2`
Expected: 0 failures (rendering smoke tests exercise the new row).

- [ ] **Step 7: Commit**

```bash
git add Sources/CleanMacCore/Localization/L10n.swift Sources/CleanMacCore/Resources Sources/CleanMac/Views/AIReviewView.swift
git commit -m "feat: add per-tool model pills to the AI review screen"
```

---

### Task 5: End-to-end sanity run

**Files:** none (verification only)

- [ ] **Step 1: Rebuild and relaunch the app**

Run: `./script/build_and_run.sh run`
Expected: app opens; AI Review screen shows a 模型 row under AI 工具 with 默认 highlighted.

- [ ] **Step 2: Real-CLI spot check** — with items selected, pick Codex + `gpt-5.1`, click 询问 AI. Expected: output appears (codex is logged in). Restart the app and confirm each tool remembers its own model pill.

- [ ] **Step 3: Report results to the user.**
