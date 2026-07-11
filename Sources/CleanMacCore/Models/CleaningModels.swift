import Foundation

public enum CandidateCategory: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case cache
    case logs
    case downloads
    case trash
    case temporary
    case developer
    case largeFile
    case application
    case applicationSupport
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
        case .application: "Applications"
        case .applicationSupport: "App Support"
        case .other: "Other"
        }
    }

    public func displayName(language: ResolvedLanguage) -> String {
        L10n.categoryName(self, language: language)
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
        case .application: "app"
        case .applicationSupport: "shippingbox"
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

    public func displayName(language: ResolvedLanguage) -> String {
        L10n.riskName(self, language: language)
    }
}

public enum DeletionProtection: String, CaseIterable, Codable, Hashable, Identifiable, Sendable {
    case allowed
    case requiresReview
    case blocked

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .allowed: "Allowed"
        case .requiresReview: "Review Required"
        case .blocked: "Protected"
        }
    }

    public func displayName(language: ResolvedLanguage) -> String {
        L10n.protectionName(self, language: language)
    }

    public var symbolName: String {
        switch self {
        case .allowed: "checkmark.shield"
        case .requiresReview: "eye"
        case .blocked: "lock.shield"
        }
    }
}

public struct SafetyRuleMatch: Identifiable, Hashable, Codable, Sendable {
    public var id: String { ruleID }

    public let ruleID: String
    public let name: String
    public let explanation: String
    public let protection: DeletionProtection

    public init(
        ruleID: String,
        name: String,
        explanation: String,
        protection: DeletionProtection
    ) {
        self.ruleID = ruleID
        self.name = name
        self.explanation = explanation
        self.protection = protection
    }
}

public struct SafetyEvaluation: Equatable, Sendable {
    public let protection: DeletionProtection
    public let ruleMatches: [SafetyRuleMatch]
    public let userVisibleRules: [String]

    public init(
        protection: DeletionProtection,
        ruleMatches: [SafetyRuleMatch],
        userVisibleRules: [String]
    ) {
        self.protection = protection
        self.ruleMatches = ruleMatches
        self.userVisibleRules = userVisibleRules
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
    public let protection: DeletionProtection
    public let ruleMatches: [SafetyRuleMatch]
    public let userVisibleRules: [String]

    public init(
        url: URL,
        sizeBytes: Int64,
        modifiedAt: Date?,
        category: CandidateCategory,
        risk: DeletionRisk,
        reasons: [String],
        isDirectory: Bool,
        protection: DeletionProtection = .requiresReview,
        ruleMatches: [SafetyRuleMatch] = [],
        userVisibleRules: [String] = []
    ) {
        self.url = url
        self.sizeBytes = sizeBytes
        self.modifiedAt = modifiedAt
        self.category = category
        self.risk = risk
        self.reasons = reasons
        self.isDirectory = isDirectory
        self.protection = protection
        self.ruleMatches = ruleMatches
        self.userVisibleRules = userVisibleRules
    }
}

public struct ScanClassification: Equatable, Sendable {
    public let category: CandidateCategory
    public let risk: DeletionRisk
    public let reasons: [String]
    public let protection: DeletionProtection
    public let ruleMatches: [SafetyRuleMatch]
    public let userVisibleRules: [String]

    public init(
        category: CandidateCategory,
        risk: DeletionRisk,
        reasons: [String],
        protection: DeletionProtection = .requiresReview,
        ruleMatches: [SafetyRuleMatch] = [],
        userVisibleRules: [String] = []
    ) {
        self.category = category
        self.risk = risk
        self.reasons = reasons
        self.protection = protection
        self.ruleMatches = ruleMatches
        self.userVisibleRules = userVisibleRules
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
    public let duplicateGroups: [DuplicateFileGroup]
    public let totalBytes: Int64
    public let scannedFileCount: Int
    public let skippedFileCount: Int

    public var duplicateReclaimableBytes: Int64 {
        duplicateGroups.reduce(0) { $0 + $1.movableReclaimableBytes }
    }

    public init(
        candidates: [CleaningCandidate],
        duplicateGroups: [DuplicateFileGroup] = [],
        totalBytes: Int64,
        scannedFileCount: Int,
        skippedFileCount: Int
    ) {
        self.candidates = candidates
        self.duplicateGroups = duplicateGroups
        self.totalBytes = totalBytes
        self.scannedFileCount = scannedFileCount
        self.skippedFileCount = skippedFileCount
    }
}

public struct DuplicateFileGroup: Identifiable, Hashable, Codable, Sendable {
    public var id: String { "\(sizeBytes)-\(contentHash)" }

    public let contentHash: String
    public let sizeBytes: Int64
    public let candidates: [CleaningCandidate]

    public var reclaimableBytes: Int64 {
        guard candidates.count > 1 else { return 0 }
        return sizeBytes * Int64(candidates.count - 1)
    }

    public var movableReclaimableBytes: Int64 {
        movableDuplicateCandidates.reduce(0) { $0 + $1.sizeBytes }
    }

    public var preferredOriginal: CleaningCandidate? {
        candidates.sortedForDuplicateRetention().first
    }

    public var duplicateCandidates: [CleaningCandidate] {
        Array(candidates.sortedForDuplicateRetention().dropFirst())
    }

    public var movableDuplicateCandidates: [CleaningCandidate] {
        duplicateCandidates.filter { $0.protection != .blocked }
    }

    public init(contentHash: String, sizeBytes: Int64, candidates: [CleaningCandidate]) {
        self.contentHash = contentHash
        self.sizeBytes = sizeBytes
        self.candidates = candidates
    }
}

public struct AppUninstallPlan: Identifiable, Hashable, Codable, Sendable {
    public var id: String { appCandidate.id }

    public let appName: String
    public let bundleIdentifier: String
    public let appCandidate: CleaningCandidate

    public var allCandidates: [CleaningCandidate] {
        [appCandidate]
    }

    public var movableCandidates: [CleaningCandidate] {
        allCandidates.filter { $0.protection != .blocked }
    }

    public var reclaimableBytes: Int64 {
        allCandidates.reduce(0) { $0 + $1.sizeBytes }
    }

    public var movableReclaimableBytes: Int64 {
        movableCandidates.reduce(0) { $0 + $1.sizeBytes }
    }

    public init(
        appName: String,
        bundleIdentifier: String,
        appCandidate: CleaningCandidate
    ) {
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier
        self.appCandidate = appCandidate
    }
}

private extension Array where Element == CleaningCandidate {
    func sortedForDuplicateRetention() -> [CleaningCandidate] {
        sorted { lhs, rhs in
            switch (lhs.modifiedAt, rhs.modifiedAt) {
            case let (lhsDate?, rhsDate?) where lhsDate != rhsDate:
                return lhsDate > rhsDate
            case (_?, nil):
                return true
            case (nil, _?):
                return false
            default:
                return lhs.url.path.localizedStandardCompare(rhs.url.path) == .orderedAscending
            }
        }
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

    public mutating func selectMovable(_ candidates: [CleaningCandidate]) {
        selectedIDs.formUnion(candidates.filter { $0.protection != .blocked }.map(\.id))
    }

    public mutating func selectDuplicateCopies(in groups: [DuplicateFileGroup]) {
        selectedIDs.formUnion(groups.flatMap(\.movableDuplicateCandidates).map(\.id))
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
    public let skipped: [CleanupSkippedItem]

    public init(
        cleanedCount: Int,
        reclaimedBytes: Int64,
        failures: [CleanupFailure],
        skipped: [CleanupSkippedItem] = []
    ) {
        self.cleanedCount = cleanedCount
        self.reclaimedBytes = reclaimedBytes
        self.failures = failures
        self.skipped = skipped
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

public struct CleanupSkippedItem: Equatable, Sendable {
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
    /// Environment for the spawned process. `nil` inherits the parent's environment;
    /// a value replaces it wholesale (used to hand the child an augmented `PATH`).
    public var environment: [String: String]?
    /// Working directory for the spawned process. `nil` inherits the parent's cwd —
    /// which is "/" for a Finder-launched app, never the right context for a CLI.
    public var workingDirectory: String?

    public init(executable: String, arguments: [String] = [], environment: [String: String]? = nil, workingDirectory: String? = nil) {
        self.executable = executable
        self.arguments = arguments
        self.environment = environment
        self.workingDirectory = workingDirectory
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
