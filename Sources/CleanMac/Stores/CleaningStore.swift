import AppKit
import CleanMacCore
import Foundation

@MainActor
final class CleaningStore: ObservableObject {
    @Published var roots: [URL] = DefaultScanRoots.urls {
        didSet { refreshVolumeSnapshot() }
    }
    @Published var appRoots: [URL] = DefaultApplicationRoots.urls
    @Published var candidates: [CleaningCandidate] = []
    @Published var selection = CleaningSelection()
    @Published var selectedCandidateID: CleaningCandidate.ID?
    @Published var lastReport: ScanReport?
    @Published var uninstallPlans: [AppUninstallPlan] = []
    @Published var cleanupResult: CleanupResult?
    @Published var aiQuestion: String
    @Published var aiOutput = ""
    @Published var aiReviewSummary: AIReviewSummary?
    @Published var status: CleaningStatus = .ready
    @Published var errorMessage: CleaningErrorMessage?
    @Published var isScanning = false
    @Published var isCleaning = false
    @Published var isReviewingWithAI = false
    @Published var isScanningApplications = false
    @Published var includeHiddenFiles = false
    @Published var minimumSizeMegabytes = 1.0
    @Published var largeFileThresholdMegabytes = 500.0
    @Published var volumeSnapshot: StorageVolumeSnapshot?
    @Published var detectedAITools: [DetectedAITool] = []
    @Published var selectedAIToolID: String?
    @Published var selectedModelIDsByTool: [String: String]

    private let aiToolDetector: AIToolDetector
    private static let aiToolPreferenceKey = "aiSelectedToolID"
    private static let aiModelPreferenceKey = "aiModelPreferenceByTool"

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
    func applyAIReviewOutput(_ output: String) {
        aiOutput = output
        aiReviewSummary = AIReviewOutputParser.parse(output)
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

    var selectedCandidate: CleaningCandidate? {
        guard let selectedCandidateID else { return nil }
        return candidates.first { $0.id == selectedCandidateID }
    }

    func updateDefaultAIQuestionIfNeeded(language: ResolvedLanguage) {
        guard L10n.isDefaultAIQuestion(aiQuestion) else { return }
        aiQuestion = L10n.defaultAIQuestion(language: language)
    }

    func addFolderWithOpenPanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = false
        panel.prompt = L10n.text(.add, language: AppLanguage(storedRawValue: UserDefaults.standard.string(forKey: AppLanguage.storageKey)).resolved())

        guard panel.runModal() == .OK else { return }
        let additions = panel.urls.filter { !roots.contains($0) }
        roots.append(contentsOf: additions)
    }

    func removeRoot(_ url: URL) {
        roots.removeAll { $0 == url }
    }

    func addApplicationFolderWithOpenPanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = false
        panel.prompt = L10n.text(.add, language: AppLanguage(storedRawValue: UserDefaults.standard.string(forKey: AppLanguage.storageKey)).resolved())

        guard panel.runModal() == .OK else { return }
        let additions = panel.urls.filter { !appRoots.contains($0) }
        appRoots.append(contentsOf: additions)
    }

    func removeApplicationRoot(_ url: URL) {
        appRoots.removeAll { $0 == url }
    }

    func scan() {
        guard !roots.isEmpty else {
            errorMessage = .addFolderToScan
            return
        }
        guard !isScanning, !isScanningApplications else { return }
        refreshVolumeSnapshot()

        let roots = roots
        let options = ScanOptions(
            minimumFileSizeBytes: Int64(minimumSizeMegabytes * 1_024 * 1_024),
            includeHiddenFiles: includeHiddenFiles,
            largeFileThresholdBytes: Int64(largeFileThresholdMegabytes * 1_024 * 1_024)
        )

        isScanning = true
        errorMessage = nil
        cleanupResult = nil
        status = .scanning

        Task {
            do {
                let report = try await Task.detached(priority: .userInitiated) {
                    try DiskScanner().scan(roots: roots, options: options)
                }
                .value
                lastReport = report
                candidates = report.candidates
                uninstallPlans = []
                selection.clear()
                selectedCandidateID = candidates.first?.id
                status = .candidatesFound(report.candidates.count)
            } catch {
                errorMessage = .system(error.localizedDescription)
                status = .scanFailed
            }
            isScanning = false
        }
    }

    func scanApplications() {
        guard !appRoots.isEmpty else {
            errorMessage = .addFolderToScan
            return
        }
        guard !isScanning, !isScanningApplications else { return }

        let appRoots = appRoots
        let userLibrary = FileManager.default.homeDirectoryForCurrentUser
            .appending(path: "Library", directoryHint: .isDirectory)

        isScanningApplications = true
        errorMessage = nil
        cleanupResult = nil
        status = .scanning

        Task {
            do {
                let plans = try await Task.detached(priority: .userInitiated) {
                    try AppUninstaller().scan(appRoots: appRoots, userLibrary: userLibrary)
                }
                .value
                let candidates = plans.flatMap(\.allCandidates)
                let duplicateGroups = await Self.duplicateGroupsOffMainActor(for: candidates)
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
            } catch {
                errorMessage = .system(error.localizedDescription)
                status = .scanFailed
            }
            isScanningApplications = false
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
        let targets = selectedCandidates
        guard !targets.isEmpty else { return }
        guard !isCleaning else { return }

        isCleaning = true
        errorMessage = nil
        status = .movingToTrash

        Task {
            do {
                let result = try await Task.detached(priority: .userInitiated) {
                    try TrashCleaner().clean(targets)
                }
                .value
                cleanupResult = result

                let failedURLs = Set(result.failures.map(\.url))
                let skippedURLs = Set(result.skipped.map(\.url))
                let cleanedIDs = Set(targets.filter {
                    !failedURLs.contains($0.url) && !skippedURLs.contains($0.url)
                }.map(\.id))
                candidates.removeAll { cleanedIDs.contains($0.id) }
                uninstallPlans = uninstallPlans.map { plan in
                    AppUninstallPlan(
                        appName: plan.appName,
                        bundleIdentifier: plan.bundleIdentifier,
                        appCandidate: plan.appCandidate,
                        supportCandidates: plan.supportCandidates.filter { !cleanedIDs.contains($0.id) }
                    )
                }
                .filter { !cleanedIDs.contains($0.appCandidate.id) }
                await refreshReportAfterCandidateChanges()
                selection.clear()
                selectedCandidateID = candidates.first?.id
                status = .movedToTrash(result.cleanedCount)
                if !result.failures.isEmpty {
                    errorMessage = .itemsCouldNotBeMoved(result.failures.count)
                } else if !result.skipped.isEmpty {
                    errorMessage = .itemsWereProtected(result.skipped.count)
                }
            } catch {
                errorMessage = .system(error.localizedDescription)
                status = .cleanupFailed
            }
            isCleaning = false
        }
    }

    func askAI() {
        let targets = selectedCandidates
        guard !targets.isEmpty else {
            errorMessage = .selectItemForAIReview
            return
        }
        refreshDetectedAITools()
        guard let selectedAIToolID, let tool = detectedAITools.first(where: { $0.id == selectedAIToolID }) else {
            errorMessage = .noAIToolDetected
            return
        }
        guard !isReviewingWithAI else { return }

        isReviewingWithAI = true
        errorMessage = nil
        aiOutput = ""
        aiReviewSummary = nil
        status = .askingAI

        let question = aiQuestion
        let model = selectedModelOption(for: tool.id)

        Task {
            do {
                let review = try await AIReviewService(tool: tool)
                    .review(candidates: targets, userQuestion: question, model: model)
                applyAIReviewOutput(review.output)
                status = .aiReviewFinished
            } catch {
                errorMessage = .system(error.localizedDescription)
                status = .aiReviewFailed
            }
            isReviewingWithAI = false
        }
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
