# Duplicate File Detection Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Detect duplicate files by content, estimate reclaimable space, and let users select duplicate copies while preserving one file per duplicate group.

**Architecture:** `CleanMacCore` owns duplicate grouping and preferred-original selection so the cleanup policy is testable. `DiskScanner` attaches duplicate groups to `ScanReport`; `CleaningStore` exposes duplicate summaries and selection; SwiftUI surfaces those summaries in the existing scan/results workflow.

**Tech Stack:** Swift 6, SwiftPM, XCTest, CryptoKit SHA-256 hashing, SwiftUI for macOS.

---

## File Structure

- Create: `Sources/CleanMacCore/Services/DuplicateFileFinder.swift`
- Create: `Tests/CleanMacCoreTests/DuplicateFileFinderTests.swift`
- Modify: `Sources/CleanMacCore/Models/CleaningModels.swift`
- Modify: `Sources/CleanMacCore/Services/DiskScanner.swift`
- Modify: `Tests/CleanMacCoreTests/DiskScannerTests.swift`
- Modify: `Tests/CleanMacCoreTests/CleaningSelectionTests.swift`
- Modify: `Sources/CleanMac/Stores/CleaningStore.swift`
- Modify: `Sources/CleanMac/Views/ScanView.swift`
- Modify: `Sources/CleanMac/Views/ResultsView.swift`
- Modify: `Sources/CleanMacCore/Localization/L10n.swift`

### Task 1: Duplicate Finder Core

**Files:**
- Create: `Tests/CleanMacCoreTests/DuplicateFileFinderTests.swift`
- Create: `Sources/CleanMacCore/Services/DuplicateFileFinder.swift`
- Modify: `Sources/CleanMacCore/Models/CleaningModels.swift`

- [x] **Step 1: Write failing duplicate finder tests**

```swift
func testFindsDuplicateGroupsByContentHashNotNameOrSizeOnly() throws {
    let root = try makeTemporaryDirectory()
    let first = try writeFile(root.appending(path: "a/report.txt"), contents: "same")
    let second = try writeFile(root.appending(path: "b/copy.txt"), contents: "same")
    _ = try writeFile(root.appending(path: "c/not-a-copy.txt"), contents: "diff")

    let groups = try DuplicateFileFinder().findDuplicates(in: [
        candidate(url: first, size: 4),
        candidate(url: second, size: 4),
        candidate(url: root.appending(path: "c/not-a-copy.txt"), size: 4)
    ])

    XCTAssertEqual(groups.count, 1)
    XCTAssertEqual(groups[0].candidates.map(\.url.lastPathComponent).sorted(), ["copy.txt", "report.txt"])
    XCTAssertEqual(groups[0].reclaimableBytes, 4)
}

func testPreferredOriginalKeepsNewestFileAndSelectsOnlyMovableCopies() {
    let old = candidate(path: "/tmp/old.txt", size: 10, modifiedAt: Date(timeIntervalSince1970: 1), protection: .allowed)
    let new = candidate(path: "/tmp/new.txt", size: 10, modifiedAt: Date(timeIntervalSince1970: 2), protection: .allowed)
    let blocked = candidate(path: "/System/copy.txt", size: 10, modifiedAt: Date(timeIntervalSince1970: 0), protection: .blocked)
    let group = DuplicateFileGroup(contentHash: "hash", sizeBytes: 10, candidates: [old, new, blocked])

    XCTAssertEqual(group.preferredOriginal?.url.path, new.url.path)
    XCTAssertEqual(group.movableDuplicateCandidates.map(\.url.path), [old.url.path])
}
```

- [x] **Step 2: Run duplicate finder tests to verify they fail**

Run: `env CLANG_MODULE_CACHE_PATH=/Users/luoguoqiu/Documents/CleanMac/.build/module-cache swift test --filter DuplicateFileFinderTests`

Expected: FAIL because `DuplicateFileFinder` and `DuplicateFileGroup` do not exist.

- [x] **Step 3: Implement duplicate models and SHA-256 finder**

Add `DuplicateFileGroup` to `CleaningModels.swift`. Add `DuplicateFileFinder` that groups non-directory candidates by size first, hashes same-size candidates with SHA-256, returns only content hashes with at least two candidates, and sorts groups by descending reclaimable bytes.

- [x] **Step 4: Run duplicate finder tests to verify they pass**

Run: `env CLANG_MODULE_CACHE_PATH=/Users/luoguoqiu/Documents/CleanMac/.build/module-cache swift test --filter DuplicateFileFinderTests`

Expected: PASS.

### Task 2: Scan Report Integration

**Files:**
- Modify: `Tests/CleanMacCoreTests/DiskScannerTests.swift`
- Modify: `Sources/CleanMacCore/Models/CleaningModels.swift`
- Modify: `Sources/CleanMacCore/Services/DiskScanner.swift`

- [x] **Step 1: Write failing scanner duplicate report test**

```swift
func testScanReportsDuplicateGroupsAndReclaimableBytes() throws {
    let root = try makeTemporaryDirectory()
    try writeFile(root.appending(path: "one.txt"), byteCount: 6)
    try writeFile(root.appending(path: "copy/one-copy.txt"), byteCount: 6)

    let report = try DiskScanner(classifier: ScanClassifier(largeFileThresholdBytes: 100))
        .scan(roots: [root], options: ScanOptions(minimumFileSizeBytes: 1, includeHiddenFiles: false))

    XCTAssertEqual(report.duplicateGroups.count, 1)
    XCTAssertEqual(report.duplicateReclaimableBytes, 6)
}
```

- [x] **Step 2: Run scanner duplicate test to verify it fails**

Run: `env CLANG_MODULE_CACHE_PATH=/Users/luoguoqiu/Documents/CleanMac/.build/module-cache swift test --filter DiskScannerTests/testScanReportsDuplicateGroupsAndReclaimableBytes`

Expected: FAIL because `ScanReport` does not yet expose duplicate groups.

- [x] **Step 3: Attach duplicate groups to scan reports**

Add `duplicateGroups` to `ScanReport`, derive `duplicateReclaimableBytes`, and call `DuplicateFileFinder().findDuplicates(in: candidates)` before returning the report.

- [x] **Step 4: Run scanner duplicate test to verify it passes**

Run: `env CLANG_MODULE_CACHE_PATH=/Users/luoguoqiu/Documents/CleanMac/.build/module-cache swift test --filter DiskScannerTests/testScanReportsDuplicateGroupsAndReclaimableBytes`

Expected: PASS.

### Task 3: Selection And UI Surface

**Files:**
- Modify: `Tests/CleanMacCoreTests/CleaningSelectionTests.swift`
- Modify: `Sources/CleanMacCore/Models/CleaningModels.swift`
- Modify: `Sources/CleanMac/Stores/CleaningStore.swift`
- Modify: `Sources/CleanMac/Views/ScanView.swift`
- Modify: `Sources/CleanMac/Views/ResultsView.swift`
- Modify: `Sources/CleanMacCore/Localization/L10n.swift`

- [x] **Step 1: Write failing selection test**

```swift
func testSelectDuplicateCopiesSelectsOnlyMovableCopiesAndPreservesOneOriginal() {
    let original = candidate(path: "/tmp/new.txt", size: 10, category: .other, protection: .allowed)
    let duplicate = candidate(path: "/tmp/old.txt", size: 10, category: .other, protection: .allowed)
    let blocked = candidate(path: "/System/copy.txt", size: 10, category: .other, protection: .blocked)
    let group = DuplicateFileGroup(contentHash: "hash", sizeBytes: 10, candidates: [duplicate, original, blocked])
    var selection = CleaningSelection()

    selection.selectDuplicateCopies(in: [group])

    XCTAssertTrue(selection.contains(duplicate))
    XCTAssertFalse(selection.contains(original))
    XCTAssertFalse(selection.contains(blocked))
}
```

- [x] **Step 2: Run selection test to verify it fails**

Run: `env CLANG_MODULE_CACHE_PATH=/Users/luoguoqiu/Documents/CleanMac/.build/module-cache swift test --filter CleaningSelectionTests/testSelectDuplicateCopiesSelectsOnlyMovableCopiesAndPreservesOneOriginal`

Expected: FAIL because duplicate-copy selection does not exist.

- [x] **Step 3: Implement selection and UI**

Add `CleaningSelection.selectDuplicateCopies(in:)`; expose duplicate groups and reclaimable bytes from `CleaningStore`; add summary tiles and a results button to select duplicate copies; show selected candidate duplicate group context in details.

- [x] **Step 4: Run full verification**

Run: `env CLANG_MODULE_CACHE_PATH=/Users/luoguoqiu/Documents/CleanMac/.build/module-cache swift test && ./script/build_and_run.sh --verify`

Expected: PASS for tests and build verification.
