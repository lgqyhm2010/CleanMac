# Safety Rules And Delete Protection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a user-visible safety rule library and enforce it before CleanMac moves anything to Trash.

**Architecture:** `CleanMacCore` owns rule evaluation and cleanup enforcement so protection is testable outside SwiftUI. `CleanMac` displays the rule names/reasons and prevents protected selections from being sent to `TrashCleaner`.

**Tech Stack:** Swift 6, SwiftPM, XCTest, SwiftUI for macOS.

---

## File Structure

- Create: `Sources/CleanMacCore/Services/SafetyRuleEngine.swift`
- Modify: `Sources/CleanMacCore/Models/CleaningModels.swift`
- Modify: `Sources/CleanMacCore/Services/ScanClassifier.swift`
- Modify: `Sources/CleanMacCore/Services/TrashCleaner.swift`
- Modify: `Sources/CleanMac/Stores/CleaningStore.swift`
- Modify: `Sources/CleanMac/Views/ResultsView.swift`
- Modify: `Sources/CleanMacCore/Localization/L10n.swift`
- Test: `Tests/CleanMacCoreTests/SafetyRuleEngineTests.swift`
- Test: `Tests/CleanMacCoreTests/TrashCleanerTests.swift`
- Test: `Tests/CleanMacCoreTests/AIReviewServiceTests.swift`

### Task 1: Safety Rule Engine

**Files:**
- Create: `Tests/CleanMacCoreTests/SafetyRuleEngineTests.swift`
- Create: `Sources/CleanMacCore/Services/SafetyRuleEngine.swift`
- Modify: `Sources/CleanMacCore/Models/CleaningModels.swift`
- Modify: `Sources/CleanMacCore/Services/ScanClassifier.swift`

- [x] **Step 1: Write failing rule tests**

```swift
func testProtectsSystemAndPersonalSourcePaths() {
    let engine = SafetyRuleEngine()

    let system = engine.evaluate(
        url: URL(filePath: "/System/Library/Extensions/Audio.kext"),
        category: .other,
        risk: .reviewRecommended,
        reasons: []
    )
    XCTAssertEqual(system.protection, .blocked)
    XCTAssertTrue(system.ruleMatches.contains { $0.ruleID == "system-root" })

    let source = engine.evaluate(
        url: URL(filePath: "/Users/me/Projects/App/Sources/main.swift"),
        category: .developer,
        risk: .reviewRecommended,
        reasons: []
    )
    XCTAssertEqual(source.protection, .requiresReview)
    XCTAssertTrue(source.ruleMatches.contains { $0.ruleID == "source-code" })
}

func testAllowsVisibleCleanupRulesForCacheAndLogs() {
    let engine = SafetyRuleEngine()

    let cache = engine.evaluate(
        url: URL(filePath: "/Users/me/Library/Caches/com.example/blob.cache"),
        category: .cache,
        risk: .usuallySafe,
        reasons: ["Cache directory item"]
    )

    XCTAssertEqual(cache.protection, .allowed)
    XCTAssertTrue(cache.ruleMatches.contains { $0.ruleID == "cache" })
    XCTAssertTrue(cache.userVisibleRules.contains { $0.localizedCaseInsensitiveContains("cache") })
}
```

- [x] **Step 2: Run rule tests to verify they fail**

Run: `env CLANG_MODULE_CACHE_PATH=/Users/luoguoqiu/Documents/CleanMac/.build/module-cache swift test --filter SafetyRuleEngineTests`

Expected: FAIL because `SafetyRuleEngine`, `DeletionProtection`, and rule match models do not exist yet.

- [x] **Step 3: Implement the safety rule models and engine**

Add `DeletionProtection`, `SafetyRuleMatch`, and rule evaluation output to `CleaningModels.swift`; implement path-based rules in `SafetyRuleEngine.swift`. The minimal rule set must include system roots, user Library app data, source code, caches, logs, temp files, downloads, large files, trash, and unknown directories.

- [x] **Step 4: Attach safety evaluation to scan classification**

Update `ScanClassification` and `CleaningCandidate` so scanned candidates carry `protection`, `ruleMatches`, and `userVisibleRules`. Update `ScanClassifier.classify` to evaluate the safety engine after assigning category/risk/reasons.

- [x] **Step 5: Run rule tests to verify they pass**

Run: `env CLANG_MODULE_CACHE_PATH=/Users/luoguoqiu/Documents/CleanMac/.build/module-cache swift test --filter SafetyRuleEngineTests`

Expected: PASS.

### Task 2: TrashCleaner Protection

**Files:**
- Modify: `Tests/CleanMacCoreTests/TrashCleanerTests.swift`
- Modify: `Sources/CleanMacCore/Services/TrashCleaner.swift`
- Modify: `Sources/CleanMacCore/Models/CleaningModels.swift`

- [x] **Step 1: Write failing cleanup protection test**

```swift
func testCleanerDoesNotTrashBlockedCandidates() throws {
    let trasher = RecordingFileTrasher()
    let cleaner = TrashCleaner(trasher: trasher)
    let safe = candidate(path: "/tmp/a.cache", size: 10, protection: .allowed)
    let blocked = candidate(path: "/System/Library/do-not-touch", size: 20, protection: .blocked)

    let result = try cleaner.clean([safe, blocked])

    XCTAssertEqual(trasher.urls, [safe.url])
    XCTAssertEqual(result.cleanedCount, 1)
    XCTAssertEqual(result.reclaimedBytes, 10)
    XCTAssertEqual(result.skipped.count, 1)
    XCTAssertEqual(result.skipped.first?.url, blocked.url)
}
```

- [x] **Step 2: Run cleanup test to verify it fails**

Run: `env CLANG_MODULE_CACHE_PATH=/Users/luoguoqiu/Documents/CleanMac/.build/module-cache swift test --filter TrashCleanerTests/testCleanerDoesNotTrashBlockedCandidates`

Expected: FAIL because `CleanupResult.skipped` and `CleaningCandidate.protection` do not exist yet, or because blocked candidates are still trashed.

- [x] **Step 3: Implement cleanup skip reporting**

Add `CleanupSkippedItem` and `skipped` to `CleanupResult`. Update `TrashCleaner.clean` to skip candidates where `candidate.protection == .blocked`.

- [x] **Step 4: Run cleanup tests to verify they pass**

Run: `env CLANG_MODULE_CACHE_PATH=/Users/luoguoqiu/Documents/CleanMac/.build/module-cache swift test --filter TrashCleanerTests`

Expected: PASS.

### Task 3: AI Prompt And SwiftUI Visibility

**Files:**
- Modify: `Tests/CleanMacCoreTests/AIReviewServiceTests.swift`
- Modify: `Sources/CleanMacCore/Services/AIReviewService.swift`
- Modify: `Sources/CleanMac/Stores/CleaningStore.swift`
- Modify: `Sources/CleanMac/Views/ResultsView.swift`
- Modify: `Sources/CleanMacCore/Localization/L10n.swift`

- [x] **Step 1: Write failing AI prompt test**

```swift
XCTAssertTrue(prompt.contains("protection:"))
XCTAssertTrue(prompt.contains("rules:"))
```

- [x] **Step 2: Run AI prompt test to verify it fails**

Run: `env CLANG_MODULE_CACHE_PATH=/Users/luoguoqiu/Documents/CleanMac/.build/module-cache swift test --filter AIReviewServiceTests/testPromptIncludesCandidateContextAndUserQuestion`

Expected: FAIL because prompt rows do not include protection or rules.

- [x] **Step 3: Add prompt and UI visibility**

Update AI prompt rows to include protection and user-visible rules. Update `CleaningStore.selectAll()` to select only non-blocked candidates and `cleanSelected()` to send only non-blocked candidates. Update `ResultsView` to show protection badges and rule text in the table/detail/confirmation message.

- [x] **Step 4: Run full verification**

Run: `env CLANG_MODULE_CACHE_PATH=/Users/luoguoqiu/Documents/CleanMac/.build/module-cache swift test && ./script/build_and_run.sh --verify`

Expected: PASS for tests and build verification.
