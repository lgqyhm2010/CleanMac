import CleanMacCore
import Foundation
import Observation

enum ForegroundOperation: Equatable {
    case scanningFiles
    case scanningApplications
    case cleaning
    case reviewingWithAI
}

struct ForegroundOperationState {
    private(set) var operation: ForegroundOperation?
    private var token: UUID?

    mutating func begin(_ operation: ForegroundOperation) -> UUID? {
        guard self.operation == nil else { return nil }
        let token = UUID()
        self.operation = operation
        self.token = token
        return token
    }

    func isCurrent(_ token: UUID) -> Bool {
        self.token == token
    }

    @discardableResult
    mutating func finish(_ token: UUID) -> Bool {
        guard self.token == token else { return false }
        operation = nil
        self.token = nil
        return true
    }
}

@Observable
@MainActor
final class CleaningStore {
    var roots: [URL] = DefaultScanRoots.urls {
        didSet { refreshVolumeSnapshot() }
    }
    var appRoots: [URL] = DefaultApplicationRoots.urls
    var candidates: [CleaningCandidate] = []
    var selection = CleaningSelection()
    var selectedCandidateID: CleaningCandidate.ID?
    var lastReport: ScanReport?
    var uninstallPlans: [AppUninstallPlan] = []
    var cleanupResult: CleanupResult?
    var aiQuestion: String
    var aiOutput = ""
    var aiReviewSummary: AIReviewSummary?
    var status: CleaningStatus = .ready
    var errorMessage: CleaningErrorMessage?
    private(set) var foregroundOperationState = ForegroundOperationState()
    var includeHiddenFiles = false
    var minimumSizeMegabytes = 1.0
    var largeFileThresholdMegabytes = 500.0
    var volumeSnapshot: StorageVolumeSnapshot?
    var detectedAITools: [DetectedAITool] = []
    var selectedAIToolID: String?
    var selectedModelIDsByTool: [String: String]
    /// Non-nil only while a file scan is running; carries the scanned-file count.
    private(set) var scanProgressCount: Int?

    @ObservationIgnored private let aiToolDetector: AIToolDetector
    @ObservationIgnored private var aiReviewTask: Task<Void, Never>?
    @ObservationIgnored private var scanTask: Task<Void, Never>?
    private static let aiToolPreferenceKey = "aiSelectedToolID"
    private static let aiModelPreferenceKey = "aiModelPreferenceByTool"

    var isScanning: Bool { foregroundOperationState.operation == .scanningFiles }
    var isCleaning: Bool { foregroundOperationState.operation == .cleaning }
    var isReviewingWithAI: Bool { foregroundOperationState.operation == .reviewingWithAI }
    var isScanningApplications: Bool { foregroundOperationState.operation == .scanningApplications }
    var isBusy: Bool { foregroundOperationState.operation != nil }

    init(language: ResolvedLanguage = AppLanguage.system.resolved(), aiToolDetector: AIToolDetector = AIToolDetector()) {
        self.aiToolDetector = aiToolDetector
        aiQuestion = L10n.defaultAIQuestion(language: language)
        selectedModelIDsByTool = UserDefaults.standard.dictionary(forKey: Self.aiModelPreferenceKey) as? [String: String] ?? [:]
        refreshVolumeSnapshot()
        refreshDetectedAITools()
    }

    func refreshDetectedAITools() {
        applyDetectedTools(aiToolDetector.detectAvailableTools())
    }

    private func applyDetectedTools(_ tools: [DetectedAITool]) {
        detectedAITools = tools

        if let selectedAIToolID, tools.contains(where: { $0.id == selectedAIToolID }) {
            return
        }

        let storedID = UserDefaults.standard.string(forKey: Self.aiToolPreferenceKey)
        if let storedID, tools.contains(where: { $0.id == storedID }) {
            selectedAIToolID = storedID
        } else if tools.count == 1 {
            selectedAIToolID = tools[0].id
        } else {
            selectedAIToolID = nil
        }
    }

    func selectAITool(_ id: String) {
        selectedAIToolID = id
        UserDefaults.standard.set(id, forKey: Self.aiToolPreferenceKey)
    }

    func selectModel(_ modelID: String, for toolID: String) {
        selectedModelIDsByTool[toolID] = modelID
        UserDefaults.standard.set(selectedModelIDsByTool, forKey: Self.aiModelPreferenceKey)
    }

    /// Keeps the raw text (fallback view, copying) and derives the structured
    /// summary from it; nil summary means the UI shows the raw text.
    func applyAIReviewOutput(
        _ output: String,
        itemPathsByID: [String: String] = [:]
    ) {
        aiOutput = output
        aiReviewSummary = AIReviewOutputParser.parse(output, itemPathsByID: itemPathsByID)
    }

    /// Resolves the persisted choice against the tool's presets; unknown or missing
    /// ids degrade to the first (Default) option so removed presets never break askAI.
    func selectedModelOption(for toolID: String) -> AIModelOption? {
        guard let profile = detectedAITools.first(where: { $0.id == toolID })?.profile else { return nil }
        let storedID = selectedModelIDsByTool[toolID]
        return profile.modelOptions.first { $0.id == storedID } ?? profile.modelOptions.first
    }

    /// Called when the AI Review screen appears: clears any error bled over from another
    /// screen and refreshes the tool list off the main thread (the PATH scan is filesystem
    /// IO we don't want to run synchronously on every visit).
    func prepareAIReviewScreen() async {
        errorMessage = nil
        let detector = aiToolDetector
        let tools = await Task.detached(priority: .userInitiated) {
            detector.detectAvailableTools()
        }.value
        applyDetectedTools(tools)
    }

    var selectedCandidates: [CleaningCandidate] {
        selection.selectedCandidates(from: candidates)
    }

    var selectedMovableCandidates: [CleaningCandidate] {
        selectedCandidates.filter { $0.protection != .blocked }
    }

    var selectedProtectedCandidates: [CleaningCandidate] {
        selectedCandidates.filter { $0.protection == .blocked }
    }

    var duplicateGroups: [DuplicateFileGroup] {
        lastReport?.duplicateGroups ?? []
    }

    var duplicateReclaimableBytes: Int64 {
        lastReport?.duplicateReclaimableBytes ?? 0
    }

    var movableDuplicateCandidates: [CleaningCandidate] {
        duplicateGroups.flatMap(\.movableDuplicateCandidates)
    }

    var uninstallReclaimableBytes: Int64 {
        uninstallPlans.reduce(0) { $0 + $1.movableReclaimableBytes }
    }

    var selectedSummary: CleaningSelectionSummary {
        selection.summary(for: candidates)
    }

    var aiSelectionExceedsLimit: Bool {
        selectedSummary.selectedCount > AIReviewService.maximumCandidateCount
    }

    var selectedCandidate: CleaningCandidate? {
        guard let selectedCandidateID else { return nil }
        return candidates.first { $0.id == selectedCandidateID }
    }

    func updateDefaultAIQuestionIfNeeded(language: ResolvedLanguage) {
        guard L10n.isDefaultAIQuestion(aiQuestion) else { return }
        aiQuestion = L10n.defaultAIQuestion(language: language)
    }

    func addRoots(_ urls: [URL]) {
        let additions = urls.filter { !roots.contains($0) }
        guard !additions.isEmpty else { return }
        roots.append(contentsOf: additions)
    }

    func removeRoot(_ url: URL) {
        roots.removeAll { $0 == url }
    }

    func addApplicationRoots(_ urls: [URL]) {
        let additions = urls.filter { !appRoots.contains($0) }
        guard !additions.isEmpty else { return }
        appRoots.append(contentsOf: additions)
    }

    func removeApplicationRoot(_ url: URL) {
        appRoots.removeAll { $0 == url }
    }

    func scan() {
        guard !isBusy else { return }
        guard !roots.isEmpty else {
            errorMessage = .addFolderToScan
            return
        }
        refreshVolumeSnapshot()

        let roots = roots
        let options = ScanOptions(
            minimumFileSizeBytes: Int64(minimumSizeMegabytes * 1_024 * 1_024),
            includeHiddenFiles: includeHiddenFiles,
            largeFileThresholdBytes: Int64(largeFileThresholdMegabytes * 1_024 * 1_024)
        )

        guard let operationToken = beginForegroundOperation(.scanningFiles) else { return }
        errorMessage = nil
        cleanupResult = nil
        status = .scanning
        scanProgressCount = 0

        scanTask = Task {
            defer {
                if finishForegroundOperation(operationToken) {
                    scanProgressCount = nil
                }
                scanTask = nil
            }
            do {
                // A detached task does not inherit cancellation from this task, so
                // bridge it explicitly: cancelling `scanTask` cancels the worker too.
                let worker = Task.detached(priority: .userInitiated) {
                    try DiskScanner().scan(roots: roots, options: options) { [weak self] scannedFileCount in
                        Task { @MainActor in
                            guard let self, self.isCurrentForegroundOperation(operationToken) else { return }
                            self.scanProgressCount = scannedFileCount
                        }
                    }
                }
                let report = try await withTaskCancellationHandler {
                    try await worker.value
                } onCancel: {
                    worker.cancel()
                }
                try Task.checkCancellation()
                guard isCurrentForegroundOperation(operationToken) else { return }
                lastReport = report
                candidates = report.candidates
                uninstallPlans = []
                selection.clear()
                selectedCandidateID = candidates.first?.id
                status = .candidatesFound(report.candidates.count)
            } catch is CancellationError {
                guard isCurrentForegroundOperation(operationToken) else { return }
                errorMessage = nil
                status = .ready
            } catch {
                guard isCurrentForegroundOperation(operationToken) else { return }
                errorMessage = .system(error.localizedDescription)
                status = .scanFailed
            }
        }
    }

    func cancelScan() {
        scanTask?.cancel()
    }

    func scanApplications() {
        guard !isBusy else { return }
        guard !appRoots.isEmpty else {
            errorMessage = .addFolderToScan
            return
        }
        let appRoots = appRoots

        guard let operationToken = beginForegroundOperation(.scanningApplications) else { return }
        errorMessage = nil
        cleanupResult = nil
        status = .scanning

        scanTask = Task {
            defer {
                finishForegroundOperation(operationToken)
                scanTask = nil
            }
            do {
                // Same cancellation bridge as scan(): detached tasks must be cancelled
                // explicitly when `scanTask` is cancelled.
                let worker = Task.detached(priority: .userInitiated) {
                    try AppUninstaller().scan(appRoots: appRoots)
                }
                let plans = try await withTaskCancellationHandler {
                    try await worker.value
                } onCancel: {
                    worker.cancel()
                }
                try Task.checkCancellation()
                guard isCurrentForegroundOperation(operationToken) else { return }
                let candidates = plans.flatMap(\.allCandidates)
                let duplicateGroups = await Self.duplicateGroupsOffMainActor(for: candidates)
                guard isCurrentForegroundOperation(operationToken) else { return }
                uninstallPlans = plans
                self.candidates = candidates
                lastReport = ScanReport(
                    candidates: candidates,
                    duplicateGroups: duplicateGroups,
                    totalBytes: candidates.reduce(0) { $0 + $1.sizeBytes },
                    scannedFileCount: candidates.count,
                    skippedFileCount: 0
                )
                selection.clear()
                selectedCandidateID = candidates.first?.id
                status = .candidatesFound(candidates.count)
            } catch is CancellationError {
                guard isCurrentForegroundOperation(operationToken) else { return }
                errorMessage = nil
                status = .ready
            } catch {
                guard isCurrentForegroundOperation(operationToken) else { return }
                errorMessage = .system(error.localizedDescription)
                status = .scanFailed
            }
        }
    }

    func toggle(_ candidate: CleaningCandidate, selected: Bool) {
        let alreadySelected = selection.contains(candidate)
        guard selected != alreadySelected else { return }
        selection.toggle(candidate)
    }

    func selectAll() {
        selection.selectMovable(candidates)
    }

    func selectDuplicateCopies() {
        selection.selectDuplicateCopies(in: duplicateGroups)
    }

    func selectUninstallItems(for plan: AppUninstallPlan) {
        selection.clear()
        selection.selectMovable(plan.allCandidates)
    }

    func duplicateGroup(containing candidate: CleaningCandidate?) -> DuplicateFileGroup? {
        guard let candidate else { return nil }
        return duplicateGroups.first { group in
            group.candidates.contains { $0.id == candidate.id }
        }
    }

    func uninstallPlan(containing candidate: CleaningCandidate?) -> AppUninstallPlan? {
        guard let candidate else { return nil }
        return uninstallPlans.first { plan in
            plan.allCandidates.contains { $0.id == candidate.id }
        }
    }

    func clearSelection() {
        selection.clear()
    }

    func cleanSelected() {
        guard !isBusy else { return }
        let targets = selectedCandidates
        guard !targets.isEmpty else { return }
        let duplicateHashesByCandidateID = duplicateGroups.reduce(into: [CleaningCandidate.ID: String]()) {
            partialResult, group in
            for candidate in group.candidates {
                partialResult[candidate.id] = group.contentHash
            }
        }
        let requests = targets.map {
            CleanupRequest(
                candidate: $0,
                expectedContentHash: duplicateHashesByCandidateID[$0.id]
            )
        }

        guard let operationToken = beginForegroundOperation(.cleaning) else { return }
        errorMessage = nil
        status = .movingToTrash

        Task {
            defer { finishForegroundOperation(operationToken) }
            do {
                let result = try await Task.detached(priority: .userInitiated) {
                    try TrashCleaner().clean(requests)
                }
                .value
                guard isCurrentForegroundOperation(operationToken) else { return }
                cleanupResult = result

                let failedURLs = Set(result.failures.map(\.url))
                let skippedURLs = Set(result.skipped.map(\.url))
                let cleanedIDs = Set(targets.filter {
                    !failedURLs.contains($0.url) && !skippedURLs.contains($0.url)
                }.map(\.id))
                candidates.removeAll { cleanedIDs.contains($0.id) }
                uninstallPlans.removeAll { cleanedIDs.contains($0.appCandidate.id) }
                await refreshReportAfterCandidateChanges()
                guard isCurrentForegroundOperation(operationToken) else { return }
                selection.clear()
                selectedCandidateID = candidates.first?.id
                status = .movedToTrash(result.cleanedCount)
                if !result.failures.isEmpty {
                    errorMessage = .itemsCouldNotBeMoved(result.failures.count)
                } else if !result.skipped.isEmpty {
                    errorMessage = .itemsWereProtected(result.skipped.count)
                }
            } catch {
                guard isCurrentForegroundOperation(operationToken) else { return }
                errorMessage = .system(error.localizedDescription)
                status = .cleanupFailed
            }
        }
    }

    func askAI() {
        guard !isBusy else { return }
        let targets = selectedCandidates
        guard !targets.isEmpty else {
            errorMessage = .selectItemForAIReview
            return
        }
        guard targets.count <= AIReviewService.maximumCandidateCount else {
            errorMessage = .system(AIReviewError.tooManyCandidates(
                limit: AIReviewService.maximumCandidateCount,
                actual: targets.count
            ).localizedDescription)
            return
        }
        refreshDetectedAITools()
        guard let selectedAIToolID, let tool = detectedAITools.first(where: { $0.id == selectedAIToolID }) else {
            errorMessage = .noAIToolDetected
            return
        }
        guard let operationToken = beginForegroundOperation(.reviewingWithAI) else { return }
        errorMessage = nil
        aiOutput = ""
        aiReviewSummary = nil
        status = .askingAI

        let question = aiQuestion
        let model = selectedModelOption(for: tool.id)

        aiReviewTask = Task {
            defer {
                finishForegroundOperation(operationToken)
                aiReviewTask = nil
            }
            do {
                let review = try await AIReviewService(tool: tool)
                    .review(candidates: targets, userQuestion: question, model: model)
                try Task.checkCancellation()
                guard isCurrentForegroundOperation(operationToken) else { return }
                applyAIReviewOutput(review.output, itemPathsByID: review.itemPathsByID)
                status = .aiReviewFinished
            } catch is CancellationError {
                guard isCurrentForegroundOperation(operationToken) else { return }
                errorMessage = nil
                status = .ready
            } catch {
                guard isCurrentForegroundOperation(operationToken) else { return }
                errorMessage = .system(error.localizedDescription)
                status = .aiReviewFailed
            }
        }
    }

    func cancelAIReview() {
        aiReviewTask?.cancel()
    }

    private func beginForegroundOperation(_ operation: ForegroundOperation) -> UUID? {
        foregroundOperationState.begin(operation)
    }

    private func isCurrentForegroundOperation(_ token: UUID) -> Bool {
        foregroundOperationState.isCurrent(token)
    }

    @discardableResult
    private func finishForegroundOperation(_ token: UUID) -> Bool {
        foregroundOperationState.finish(token)
    }

    private func refreshReportAfterCandidateChanges() async {
        guard let lastReport else { return }
        let candidates = candidates
        let duplicateGroups = await Self.duplicateGroupsOffMainActor(for: candidates)
        self.lastReport = ScanReport(
            candidates: candidates,
            duplicateGroups: duplicateGroups,
            totalBytes: candidates.reduce(0) { $0 + $1.sizeBytes },
            scannedFileCount: lastReport.scannedFileCount,
            skippedFileCount: lastReport.skippedFileCount
        )
    }

    private func refreshVolumeSnapshot() {
        volumeSnapshot = StorageVolumeReporter().snapshot(
            for: roots,
            fallback: FileManager.default.homeDirectoryForCurrentUser
        )
    }

    nonisolated private static func duplicateGroupsOffMainActor(for candidates: [CleaningCandidate]) async -> [DuplicateFileGroup] {
        await Task.detached(priority: .userInitiated) {
            (try? DuplicateFileFinder().findDuplicates(in: candidates)) ?? []
        }.value
    }
}

enum DefaultScanRoots {
    static var urls: [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let candidates = [
            home.appending(path: "Downloads", directoryHint: .isDirectory),
            home.appending(path: "Library/Caches", directoryHint: .isDirectory),
            home.appending(path: "Library/Logs", directoryHint: .isDirectory),
            FileManager.default.temporaryDirectory
        ]
        return candidates.filter { FileManager.default.fileExists(atPath: $0.path) }
    }
}

enum DefaultApplicationRoots {
    static var urls: [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let candidates = [
            URL(filePath: "/Applications", directoryHint: .isDirectory),
            home.appending(path: "Applications", directoryHint: .isDirectory)
        ]
        return candidates.filter { FileManager.default.fileExists(atPath: $0.path) }
    }
}
