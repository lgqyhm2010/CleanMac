# App Uninstaller Workflow Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an app uninstaller workflow that finds app bundles, discovers related support files, and presents every item as reviewable Trash-only cleanup candidates with visible rules.

**Architecture:** `CleanMacCore` owns app bundle discovery, bundle metadata parsing, support-file matching, and candidate generation. `CleanMac` adds an Uninstaller sidebar surface that scans app roots, shows uninstall plans, and sends the generated candidates through the existing Results, AI Review, and Move to Trash flow.

**Tech Stack:** Swift 6, SwiftPM, XCTest, Foundation bundle/plist APIs, SwiftUI for macOS.

---

## File Structure

- Create: `Sources/CleanMacCore/Services/AppUninstaller.swift`
- Create: `Tests/CleanMacCoreTests/AppUninstallerTests.swift`
- Modify: `Sources/CleanMacCore/Models/CleaningModels.swift`
- Modify: `Sources/CleanMacCore/Services/SafetyRuleEngine.swift`
- Modify: `Sources/CleanMacCore/Localization/L10n.swift`
- Modify: `Sources/CleanMac/Stores/CleaningStore.swift`
- Modify: `Sources/CleanMac/Views/AppUninstallerView.swift`
- Modify: `Sources/CleanMac/Views/ContentView.swift`
- Modify: `Sources/CleanMac/Views/SidebarSection.swift`
- Modify: `Sources/CleanMac/Views/SidebarView.swift`
- Modify: `Sources/CleanMac/Views/ScanView.swift`
- Modify: `Sources/CleanMac/Views/ResultsView.swift`

### Task 1: Core App Uninstaller

**Files:**
- Create: `Tests/CleanMacCoreTests/AppUninstallerTests.swift`
- Create: `Sources/CleanMacCore/Services/AppUninstaller.swift`
- Modify: `Sources/CleanMacCore/Models/CleaningModels.swift`
- Modify: `Sources/CleanMacCore/Services/SafetyRuleEngine.swift`

- [x] **Step 1: Write failing app-uninstaller tests**

```swift
func testBuildsPlanForAppBundleAndKnownSupportFiles() throws {
    let sandbox = try makeTemporaryDirectory()
    let apps = sandbox.appending(path: "Applications", directoryHint: .isDirectory)
    let library = sandbox.appending(path: "Library", directoryHint: .isDirectory)
    let app = try makeAppBundle(apps.appending(path: "Demo.app"), bundleIdentifier: "com.example.demo")
    try writeFile(library.appending(path: "Application Support/com.example.demo/data.db"), contents: "support")
    try writeFile(library.appending(path: "Caches/com.example.demo/cache.bin"), contents: "cache")
    try writeFile(library.appending(path: "Preferences/com.example.demo.plist"), contents: "prefs")

    let plans = try AppUninstaller().scan(appRoots: [apps], userLibrary: library)

    XCTAssertEqual(plans.count, 1)
    XCTAssertEqual(plans[0].appName, "Demo")
    XCTAssertEqual(plans[0].bundleIdentifier, "com.example.demo")
    XCTAssertEqual(plans[0].appCandidate.url, app)
    XCTAssertEqual(plans[0].supportCandidates.count, 3)
    XCTAssertTrue(plans[0].allCandidates.allSatisfy { $0.protection == .requiresReview })
}

func testIgnoresNonAppDirectoriesAndRequiresBundleIdentifier() throws {
    let sandbox = try makeTemporaryDirectory()
    let apps = sandbox.appending(path: "Applications", directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: apps.appending(path: "Folder.app"), withIntermediateDirectories: true)
    try FileManager.default.createDirectory(at: apps.appending(path: "PlainFolder"), withIntermediateDirectories: true)

    let plans = try AppUninstaller().scan(appRoots: [apps], userLibrary: sandbox.appending(path: "Library"))

    XCTAssertTrue(plans.isEmpty)
}
```

- [x] **Step 2: Run app-uninstaller tests to verify they fail**

Run: `env CLANG_MODULE_CACHE_PATH=/Users/luoguoqiu/Documents/CleanMac/.build/module-cache swift test --filter AppUninstallerTests`

Expected: FAIL because `AppUninstaller`, `AppUninstallPlan`, and app-uninstall categories/rules do not exist.

- [x] **Step 3: Implement app bundle discovery and support matching**

Add `CandidateCategory.application` and `CandidateCategory.applicationSupport`. Add `AppUninstallPlan` and `AppUninstaller.scan(appRoots:userLibrary:)`. Discover `.app` bundles with valid `CFBundleIdentifier`; create a candidate for the app bundle plus support candidates under Application Support, Caches, Preferences, Saved Application State, Logs, Containers, and Group Containers when paths exist.

- [x] **Step 4: Run app-uninstaller tests to verify they pass**

Run: `env CLANG_MODULE_CACHE_PATH=/Users/luoguoqiu/Documents/CleanMac/.build/module-cache swift test --filter AppUninstallerTests`

Expected: PASS.

### Task 2: Store And UI Workflow

**Files:**
- Modify: `Sources/CleanMac/Stores/CleaningStore.swift`
- Create: `Sources/CleanMac/Views/AppUninstallerView.swift`
- Modify: `Sources/CleanMac/Views/ContentView.swift`
- Modify: `Sources/CleanMac/Views/SidebarSection.swift`
- Modify: `Sources/CleanMac/Views/SidebarView.swift`
- Modify: `Sources/CleanMac/Views/ScanView.swift`
- Modify: `Sources/CleanMac/Views/ResultsView.swift`
- Modify: `Sources/CleanMacCore/Localization/L10n.swift`

- [x] **Step 1: Add uninstaller store state**

Expose `appRoots`, `uninstallPlans`, `isScanningApps`, `scanApplications()`, `selectUninstallItems(for:)`, and `uninstallReclaimableBytes`. Scanning apps populates normal `candidates` so Results and AI Review continue to work.

- [x] **Step 2: Add Uninstaller sidebar view**

Add a sidebar section entry and `AppUninstallerView` with app roots, scan action, app plan list, reclaimable estimate, and buttons to select one app's uninstall items.

- [x] **Step 3: Show app-uninstall context in Results**

Add summary tile and detail text for app-uninstall candidates so users see which app/support rules matched before moving anything to Trash.

- [x] **Step 4: Run full verification**

Run: `env CLANG_MODULE_CACHE_PATH=/Users/luoguoqiu/Documents/CleanMac/.build/module-cache swift test && ./script/build_and_run.sh --verify`

Expected: PASS for tests and build verification.
