import Foundation
import Testing
@testable import CleanMacCore

@Suite("Storage volume reporter")
struct StorageVolumeReporterTests {
    @Test("Volume snapshot reads real filesystem capacity")
    func volumeSnapshotReadsRealFilesystemCapacity() throws {
        let snapshot = try #require(
            StorageVolumeReporter().snapshot(for: FileManager.default.temporaryDirectory)
        )

        #expect(!snapshot.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        #expect(snapshot.totalCapacityBytes > 0)
        #expect(snapshot.availableCapacityBytes >= 0)
        #expect(snapshot.usedCapacityBytes >= 0)
        #expect(snapshot.usedCapacityBytes <= snapshot.totalCapacityBytes)
    }
}
