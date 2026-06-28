# Permissions And Full Disk Access Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add system permission and Full Disk Access guidance so users understand why scans may be incomplete and can open the correct macOS Settings pane.

**Architecture:** `CleanMacCore` owns a testable permission guide model and probe abstraction. SwiftUI views render the current guidance in the scan workflow and Settings window while delegating opening System Settings to the environment.

**Tech Stack:** Swift 6, SwiftPM, XCTest, SwiftUI/AppKit macOS settings URL handling.

---

## File Structure

- Create: `Sources/CleanMacCore/Services/SystemPermissionGuide.swift`
- Create: `Tests/CleanMacCoreTests/SystemPermissionGuideTests.swift`
- Modify: `Sources/CleanMacCore/Localization/L10n.swift`
- Modify: `Sources/CleanMac/Views/ScanView.swift`
- Modify: `Sources/CleanMac/Views/SettingsView.swift`

### Task 1: Core Permission Guide

**Files:**
- Create: `Tests/CleanMacCoreTests/SystemPermissionGuideTests.swift`
- Create: `Sources/CleanMacCore/Services/SystemPermissionGuide.swift`

- [x] **Step 1: Write failing guide tests**

```swift
func testFullDiskAccessGuideUsesPrivacySettingsURLAndExplainsManualGrant() {
    let guide = SystemPermissionGuide.fullDiskAccess()

    XCTAssertEqual(guide.kind, .fullDiskAccess)
    XCTAssertEqual(guide.settingsURL?.absoluteString, "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")
    XCTAssertTrue(guide.instructions.contains { $0.localizedCaseInsensitiveContains("Full Disk Access") })
}

func testStatusIsGrantedWhenAnyProtectedProbeIsReadable() {
    let guide = SystemPermissionGuide.fullDiskAccess(
        probe: PermissionProbe(
            protectedLocations: [URL(filePath: "/Users/me/Library/Mail")],
            canReadDirectory: { $0.path.contains("Mail") }
        )
    )

    XCTAssertEqual(guide.status, .granted)
}

func testStatusNeedsAttentionWhenProtectedProbesCannotBeRead() {
    let guide = SystemPermissionGuide.fullDiskAccess(
        probe: PermissionProbe(
            protectedLocations: [URL(filePath: "/Users/me/Library/Mail")],
            canReadDirectory: { _ in false }
        )
    )

    XCTAssertEqual(guide.status, .needsAttention)
}
```

- [x] **Step 2: Run guide tests to verify they fail**

Run: `env CLANG_MODULE_CACHE_PATH=/Users/luoguoqiu/Documents/CleanMac/.build/module-cache swift test --filter SystemPermissionGuideTests`

Expected: FAIL because `SystemPermissionGuide`, `PermissionProbe`, and permission enums do not exist.

- [x] **Step 3: Implement minimal guide and probe models**

Create `SystemPermissionKind`, `SystemPermissionStatus`, `PermissionProbe`, and `SystemPermissionGuide.fullDiskAccess()`. Use the Full Disk Access System Settings URL `x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles`; do not attempt to programmatically request FDA because macOS requires manual user approval.

- [x] **Step 4: Run guide tests to verify they pass**

Run: `env CLANG_MODULE_CACHE_PATH=/Users/luoguoqiu/Documents/CleanMac/.build/module-cache swift test --filter SystemPermissionGuideTests`

Expected: PASS.

### Task 2: UI Guidance

**Files:**
- Modify: `Sources/CleanMacCore/Localization/L10n.swift`
- Modify: `Sources/CleanMac/Views/ScanView.swift`
- Modify: `Sources/CleanMac/Views/SettingsView.swift`

- [x] **Step 1: Add localized labels**

Add labels for permissions, Full Disk Access, status text, and open settings in English and Chinese.

- [x] **Step 2: Show FDA guidance in scan workflow**

Add a compact guidance panel above folders in `ScanView`, showing status, why it matters, and a button that opens the guide URL with `openURL`.

- [x] **Step 3: Add a Permissions tab in Settings**

Add a Settings tab for permissions that shows the same Full Disk Access guide and opening action.

- [x] **Step 4: Run full verification**

Run: `env CLANG_MODULE_CACHE_PATH=/Users/luoguoqiu/Documents/CleanMac/.build/module-cache swift test && ./script/build_and_run.sh --verify`

Expected: PASS for tests and build verification.
