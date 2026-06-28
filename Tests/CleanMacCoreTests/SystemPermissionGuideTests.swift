import XCTest
@testable import CleanMacCore

final class SystemPermissionGuideTests: XCTestCase {
    func testFullDiskAccessGuideUsesPrivacySettingsURLAndExplainsManualGrant() {
        let guide = SystemPermissionGuide.fullDiskAccess()

        XCTAssertEqual(guide.kind, .fullDiskAccess)
        XCTAssertEqual(
            guide.settingsURL?.absoluteString,
            "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
        )
        XCTAssertTrue(guide.instructions.contains { $0.localizedCaseInsensitiveContains("Full Disk Access") })
        XCTAssertTrue(guide.explanation.localizedCaseInsensitiveContains("scan"))
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
                protectedLocations: [
                    URL(filePath: "/Users/me/Library/Mail"),
                    URL(filePath: "/Users/me/Library/Messages")
                ],
                canReadDirectory: { _ in false }
            )
        )

        XCTAssertEqual(guide.status, .needsAttention)
    }

    func testStatusUnavailableWhenNoProtectedProbeLocationsExist() {
        let guide = SystemPermissionGuide.fullDiskAccess(
            probe: PermissionProbe(
                protectedLocations: [],
                canReadDirectory: { _ in true }
            )
        )

        XCTAssertEqual(guide.status, .unavailable)
    }
}
