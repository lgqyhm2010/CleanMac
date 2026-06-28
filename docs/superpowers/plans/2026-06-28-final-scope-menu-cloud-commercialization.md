# Final Scope Menu Cloud Commercialization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Advance the deferred final group only after the safety, permissions, duplicate, and app-uninstaller phases are working.

**Architecture:** Keep the product centered on AI review, Move to Trash, and user-visible rules. Cloud drive handling belongs in the core safety rule engine, menu bar monitoring belongs in the smallest AppKit bridge around the existing `AppDelegate`, and commercialization belongs in documentation guardrails until the trust path is stable.

**Tech Stack:** Swift 6, SwiftPM, XCTest, SwiftUI, AppKit `NSStatusItem`, Combine.

---

### Task 1: Cloud Storage Safety Rule

**Files:**
- Modify: `Tests/CleanMacCoreTests/SafetyRuleEngineTests.swift`
- Modify: `Sources/CleanMacCore/Services/SafetyRuleEngine.swift`

- [x] **Step 1: Write the failing test**

```swift
func testCloudStoragePathsRequireReviewWithVisibleRule() {
    let engine = SafetyRuleEngine()

    let iCloud = engine.evaluate(
        url: URL(filePath: "/Users/me/Library/Mobile Documents/com~apple~CloudDocs/Archive.zip"),
        category: .largeFile,
        risk: .reviewRecommended,
        reasons: []
    )

    XCTAssertEqual(iCloud.protection, .requiresReview)
    XCTAssertTrue(iCloud.ruleMatches.contains { $0.ruleID == "cloud-storage" })
    XCTAssertTrue(iCloud.userVisibleRules.contains { $0.localizedCaseInsensitiveContains("cloud") })
}
```

- [x] **Step 2: Run test to verify it fails**

Run:

```bash
env CLANG_MODULE_CACHE_PATH=/Users/luoguoqiu/Documents/CleanMac/.build/module-cache swift test --filter 'SafetyRuleEngineTests/testCloudStoragePathsRequireReviewWithVisibleRule'
```

Expected: FAIL because `cloud-storage` does not exist yet.

- [x] **Step 3: Write minimal implementation**

Add `cloud-storage` as a `.requiresReview` rule for iCloud Drive, `~/Library/CloudStorage`, Dropbox, OneDrive, and Google Drive paths.

- [x] **Step 4: Run test to verify it passes**

Run:

```bash
env CLANG_MODULE_CACHE_PATH=/Users/luoguoqiu/Documents/CleanMac/.build/module-cache swift test --filter 'SafetyRuleEngineTests/testCloudStoragePathsRequireReviewWithVisibleRule'
```

Expected: PASS.

### Task 2: Menu Bar Monitor

**Files:**
- Create: `Sources/CleanMacCore/Support/MenuBarMonitorSummary.swift`
- Create: `Tests/CleanMacCoreTests/MenuBarMonitorSummaryTests.swift`
- Modify: `Sources/CleanMac/App/CleanMacApp.swift`
- Modify: `Sources/CleanMac/Views/ContentView.swift`

- [x] **Step 1: Write the failing test**

```swift
func testTitleShowsCandidateCountWhenResultsExist() {
    XCTAssertEqual(
        MenuBarMonitorSummary.title(status: .candidatesFound(12), candidateCount: 12, isScanning: false),
        "12 items"
    )
}
```

- [x] **Step 2: Run test to verify it fails**

Run:

```bash
env CLANG_MODULE_CACHE_PATH=/Users/luoguoqiu/Documents/CleanMac/.build/module-cache swift test --filter MenuBarMonitorSummaryTests
```

Expected: FAIL because `MenuBarMonitorSummary` does not exist yet.

- [x] **Step 3: Write minimal implementation**

Create a formatter that returns `Scanning...`, `Moving...`, `AI review`, `<count> items`, or `CleanMac`, then use it from an AppKit `NSStatusItem`.

- [x] **Step 4: Wire the smallest AppKit bridge**

Make `AppDelegate` own the shared `CleaningStore`, pass that store into `ContentView(store:)`, and update an `NSStatusItem` through Combine subscriptions on `status`, `candidates`, `isScanning`, and `isScanningApplications`.

- [x] **Step 5: Run test to verify it passes**

Run:

```bash
env CLANG_MODULE_CACHE_PATH=/Users/luoguoqiu/Documents/CleanMac/.build/module-cache swift test --filter MenuBarMonitorSummaryTests
```

Expected: PASS.

### Task 3: Commercialization Guardrails

**Files:**
- Create: `docs/product/2026-06-28-commercialization-guardrails.md`

- [x] **Step 1: Write the product guardrail**

Document that the default cleanup path must stay trust-first: AI review, visible rules, and Move to Trash cannot be paywalled or bypassed.

- [x] **Step 2: Keep implementation out of the app code**

Do not add entitlements, purchase UI, subscription dependencies, or remote gating in this phase.

### Task 4: Full Verification

**Files:**
- Read: `Package.swift`
- Run: SwiftPM tests and app verify script

- [x] **Step 1: Run full verification**

Run:

```bash
env CLANG_MODULE_CACHE_PATH=/Users/luoguoqiu/Documents/CleanMac/.build/module-cache swift test && ./script/build_and_run.sh --verify
```

Expected: all tests pass and the app verification script exits 0.
