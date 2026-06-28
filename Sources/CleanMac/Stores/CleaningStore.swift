import AppKit
import CleanMacCore
import Foundation

@MainActor
final class CleaningStore: ObservableObject {
    @Published var roots: [URL] = DefaultScanRoots.urls
    @Published var candidates: [CleaningCandidate] = []
    @Published var selection = CleaningSelection()
    @Published var selectedCandidateID: CleaningCandidate.ID?
    @Published var lastReport: ScanReport?
    @Published var cleanupResult: CleanupResult?
    @Published var aiQuestion: String
    @Published var aiOutput = ""
    @Published var status: CleaningStatus = .ready
    @Published var errorMessage: CleaningErrorMessage?
    @Published var isScanning = false
    @Published var isCleaning = false
    @Published var isReviewingWithAI = false
    @Published var includeHiddenFiles = false
    @Published var minimumSizeMegabytes = 1.0
    @Published var largeFileThresholdMegabytes = 500.0

    init(language: ResolvedLanguage = AppLanguage.system.resolved()) {
        aiQuestion = L10n.defaultAIQuestion(language: language)
    }

    var selectedCandidates: [CleaningCandidate] {
        selection.selectedCandidates(from: candidates)
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

    func scan() {
        guard !roots.isEmpty else {
            errorMessage = .addFolderToScan
            return
        }

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

    func toggle(_ candidate: CleaningCandidate, selected: Bool) {
        let alreadySelected = selection.contains(candidate)
        guard selected != alreadySelected else { return }
        selection.toggle(candidate)
    }

    func selectAll() {
        selection.select(candidates)
    }

    func clearSelection() {
        selection.clear()
    }

    func cleanSelected() {
        let targets = selectedCandidates
        guard !targets.isEmpty else { return }

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
                let cleanedIDs = Set(targets.filter { !failedURLs.contains($0.url) }.map(\.id))
                candidates.removeAll { cleanedIDs.contains($0.id) }
                selection.clear()
                selectedCandidateID = candidates.first?.id
                status = .movedToTrash(result.cleanedCount)
                if !result.failures.isEmpty {
                    errorMessage = .itemsCouldNotBeMoved(result.failures.count)
                }
            } catch {
                errorMessage = .system(error.localizedDescription)
                status = .cleanupFailed
            }
            isCleaning = false
        }
    }

    func askAI(executable: String, argumentsText: String) {
        let targets = selectedCandidates
        guard !targets.isEmpty else {
            errorMessage = .selectItemForAIReview
            return
        }
        guard !executable.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = .setAIExecutable
            return
        }

        isReviewingWithAI = true
        errorMessage = nil
        aiOutput = ""
        status = .askingAI

        let command = AICommand(
            executable: executable,
            arguments: CommandLineArguments.split(argumentsText)
        )
        let question = aiQuestion

        Task {
            do {
                let review = try await AIReviewService(command: command)
                    .review(candidates: targets, userQuestion: question)
                aiOutput = review.output
                status = .aiReviewFinished
            } catch {
                errorMessage = .system(error.localizedDescription)
                status = .aiReviewFailed
            }
            isReviewingWithAI = false
        }
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
