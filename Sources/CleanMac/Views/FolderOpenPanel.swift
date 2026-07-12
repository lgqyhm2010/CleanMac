import AppKit
import CleanMacCore

/// Small view-layer helper that owns the AppKit open-panel interaction so the
/// store can stay a pure data model without any AppKit dependency.
@MainActor
enum FolderOpenPanel {
    /// Presents a modal folder picker and returns the chosen directories
    /// (empty when the user cancels).
    static func chooseFolders(language: ResolvedLanguage) -> [URL] {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = false
        panel.prompt = L10n.text(.add, language: language)

        guard panel.runModal() == .OK else { return [] }
        return panel.urls
    }
}
