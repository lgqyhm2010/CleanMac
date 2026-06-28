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
    @Published var aiQuestion = "请判断这些文件是否适合移到废纸篓，并列出需要我手动确认的项目。"
    @Published var aiOutput = ""
    @Published var statusMessage = "Ready"
    @Published var errorMessage: String?
    @Published var isScanning = false
    @Published var isCleaning = false
    @Published var isReviewingWithAI = false
    @Published var includeHiddenFiles = false
    @Published var minimumSizeMegabytes = 1.0
    @Published var largeFileThresholdMegabytes = 500.0

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

    func addFolderWithOpenPanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = false
        panel.prompt = "Add"

        guard panel.runModal() == .OK else { return }
        let additions = panel.urls.filter { !roots.contains($0) }
        roots.append(contentsOf: additions)
    }

    func removeRoot(_ url: URL) {
        roots.removeAll { $0 == url }
    }

    func scan() {
        guard !roots.isEmpty else {
            errorMessage = "Add at least one folder to scan."
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
        statusMessage = "Scanning..."

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
                statusMessage = "\(report.candidates.count) candidates found"
            } catch {
                errorMessage = error.localizedDescription
                statusMessage = "Scan failed"
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
        statusMessage = "Moving to Trash..."

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
                statusMessage = "\(result.cleanedCount) items moved to Trash"
                if !result.failures.isEmpty {
                    errorMessage = "\(result.failures.count) items could not be moved."
                }
            } catch {
                errorMessage = error.localizedDescription
                statusMessage = "Cleanup failed"
            }
            isCleaning = false
        }
    }

    func askAI(executable: String, argumentsText: String) {
        let targets = selectedCandidates
        guard !targets.isEmpty else {
            errorMessage = "Select at least one item for AI review."
            return
        }
        guard !executable.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Set an AI CLI executable in Settings."
            return
        }

        isReviewingWithAI = true
        errorMessage = nil
        aiOutput = ""
        statusMessage = "Asking AI..."

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
                statusMessage = "AI review finished"
            } catch {
                errorMessage = error.localizedDescription
                statusMessage = "AI review failed"
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
