import CleanMacCore
import SwiftUI

struct CleanerActions {
    var scan: () -> Void
    var selectAll: () -> Void
    var clearSelection: () -> Void
    var askAI: () -> Void
}

private struct CleanerActionsKey: FocusedValueKey {
    typealias Value = CleanerActions
}

extension FocusedValues {
    var cleanerActions: CleanerActions? {
        get { self[CleanerActionsKey.self] }
        set { self[CleanerActionsKey.self] = newValue }
    }
}

struct CleanerCommands: Commands {
    @FocusedValue(\.cleanerActions) private var actions
    @AppStorage(AppLanguage.storageKey) private var appLanguageRaw = AppLanguage.system.rawValue

    var body: some Commands {
        CommandMenu(L10n.text(.cleaner, language: resolvedLanguage)) {
            Button(L10n.text(.scan, language: resolvedLanguage)) {
                actions?.scan()
            }
            .keyboardShortcut("r")
            .disabled(actions == nil)

            Divider()

            Button(L10n.text(.selectAllCandidates, language: resolvedLanguage)) {
                actions?.selectAll()
            }
            .keyboardShortcut("a", modifiers: [.command, .shift])
            .disabled(actions == nil)

            Button(L10n.text(.clearSelection, language: resolvedLanguage)) {
                actions?.clearSelection()
            }
            .keyboardShortcut(.delete, modifiers: [.command, .shift])
            .disabled(actions == nil)

            Divider()

            Button(L10n.text(.askAI, language: resolvedLanguage)) {
                actions?.askAI()
            }
            .keyboardShortcut("i", modifiers: [.command, .shift])
            .disabled(actions == nil)
        }
    }

    private var resolvedLanguage: ResolvedLanguage {
        AppLanguage(storedRawValue: appLanguageRaw).resolved()
    }
}
