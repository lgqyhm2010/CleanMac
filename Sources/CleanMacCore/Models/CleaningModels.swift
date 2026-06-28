import Foundation

public enum CandidateCategory: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case cache
    case logs
    case downloads
    case trash
    case temporary
    case developer
    case largeFile
    case other

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .cache: "Caches"
        case .logs: "Logs"
        case .downloads: "Downloads"
        case .trash: "Trash"
        case .temporary: "Temporary"
        case .developer: "Developer"
        case .largeFile: "Large Files"
        case .other: "Other"
        }
    }

    public var symbolName: String {
        switch self {
        case .cache: "externaldrive.badge.icloud"
        case .logs: "doc.text.magnifyingglass"
        case .downloads: "arrow.down.circle"
        case .trash: "trash"
        case .temporary: "clock.arrow.circlepath"
        case .developer: "hammer"
        case .largeFile: "archivebox"
        case .other: "questionmark.folder"
        }
    }
}

public enum DeletionRisk: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case usuallySafe
    case reviewRecommended
    case beCareful

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .usuallySafe: "Usually Safe"
        case .reviewRecommended: "Review"
        case .beCareful: "Be Careful"
        }
    }
}

public struct CleaningCandidate: Identifiable, Hashable, Codable, Sendable {
    public var id: String { url.standardizedFileURL.path }

    public let url: URL
    public let sizeBytes: Int64
    public let modifiedAt: Date?
    public let category: CandidateCategory
    public let risk: DeletionRisk
    public let reasons: [String]
    public let isDirectory: Bool

    public init(
        url: URL,
        sizeBytes: Int64,
        modifiedAt: Date?,
        category: CandidateCategory,
        risk: DeletionRisk,
        reasons: [String],
        isDirectory: Bool
    ) {
        self.url = url
        self.sizeBytes = sizeBytes
        self.modifiedAt = modifiedAt
        self.category = category
        self.risk = risk
        self.reasons = reasons
        self.isDirectory = isDirectory
    }
}

public struct ScanClassification: Equatable, Sendable {
    public let category: CandidateCategory
    public let risk: DeletionRisk
    public let reasons: [String]

    public init(category: CandidateCategory, risk: DeletionRisk, reasons: [String]) {
        self.category = category
        self.risk = risk
        self.reasons = reasons
    }
}

public struct ScanOptions: Equatable, Sendable {
    public var minimumFileSizeBytes: Int64
    public var includeHiddenFiles: Bool
    public var largeFileThresholdBytes: Int64?

    public init(
        minimumFileSizeBytes: Int64 = 1,
        includeHiddenFiles: Bool = false,
        largeFileThresholdBytes: Int64? = nil
    ) {
        self.minimumFileSizeBytes = minimumFileSizeBytes
        self.includeHiddenFiles = includeHiddenFiles
        self.largeFileThresholdBytes = largeFileThresholdBytes
    }
}

public struct ScanReport: Equatable, Sendable {
    public let candidates: [CleaningCandidate]
    public let totalBytes: Int64
    public let scannedFileCount: Int
    public let skippedFileCount: Int

    public init(
        candidates: [CleaningCandidate],
        totalBytes: Int64,
        scannedFileCount: Int,
        skippedFileCount: Int
    ) {
        self.candidates = candidates
        self.totalBytes = totalBytes
        self.scannedFileCount = scannedFileCount
        self.skippedFileCount = skippedFileCount
    }
}

public struct CleaningSelection: Equatable, Sendable {
    public private(set) var selectedIDs: Set<CleaningCandidate.ID>

    public init(selectedIDs: Set<CleaningCandidate.ID> = []) {
        self.selectedIDs = selectedIDs
    }

    public func contains(_ candidate: CleaningCandidate) -> Bool {
        selectedIDs.contains(candidate.id)
    }

    public mutating func toggle(_ candidate: CleaningCandidate) {
        if selectedIDs.contains(candidate.id) {
            selectedIDs.remove(candidate.id)
        } else {
            selectedIDs.insert(candidate.id)
        }
    }

    public mutating func select(_ candidates: [CleaningCandidate]) {
        selectedIDs.formUnion(candidates.map(\.id))
    }

    public mutating func clear() {
        selectedIDs.removeAll()
    }

    public func selectedCandidates(from candidates: [CleaningCandidate]) -> [CleaningCandidate] {
        candidates.filter { selectedIDs.contains($0.id) }
    }

    public func summary(for candidates: [CleaningCandidate]) -> CleaningSelectionSummary {
        let selected = selectedCandidates(from: candidates)
        let counts = Dictionary(grouping: selected, by: \.category)
            .mapValues(\.count)
        return CleaningSelectionSummary(
            selectedCount: selected.count,
            totalBytes: selected.reduce(0) { $0 + $1.sizeBytes },
            countsByCategory: counts
        )
    }
}

public struct CleaningSelectionSummary: Equatable, Sendable {
    public let selectedCount: Int
    public let totalBytes: Int64
    public let countsByCategory: [CandidateCategory: Int]

    public init(selectedCount: Int, totalBytes: Int64, countsByCategory: [CandidateCategory: Int]) {
        self.selectedCount = selectedCount
        self.totalBytes = totalBytes
        self.countsByCategory = countsByCategory
    }
}

public struct CleanupResult: Equatable, Sendable {
    public let cleanedCount: Int
    public let reclaimedBytes: Int64
    public let failures: [CleanupFailure]

    public init(cleanedCount: Int, reclaimedBytes: Int64, failures: [CleanupFailure]) {
        self.cleanedCount = cleanedCount
        self.reclaimedBytes = reclaimedBytes
        self.failures = failures
    }
}

public struct CleanupFailure: Equatable, Sendable {
    public let url: URL
    public let message: String

    public init(url: URL, message: String) {
        self.url = url
        self.message = message
    }
}

public struct AICommand: Equatable, Sendable {
    public var executable: String
    public var arguments: [String]

    public init(executable: String, arguments: [String] = []) {
        self.executable = executable
        self.arguments = arguments
    }
}

public struct CommandResult: Equatable, Sendable {
    public let exitCode: Int32
    public let standardOutput: String
    public let standardError: String

    public init(exitCode: Int32, standardOutput: String, standardError: String) {
        self.exitCode = exitCode
        self.standardOutput = standardOutput
        self.standardError = standardError
    }
}

public struct AIReview: Equatable, Sendable {
    public let output: String
    public let reviewedAt: Date

    public init(output: String, reviewedAt: Date) {
        self.output = output
        self.reviewedAt = reviewedAt
    }
}
