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

    var body: some Commands {
        CommandMenu("Cleaner") {
            Button("Scan") {
                actions?.scan()
            }
            .keyboardShortcut("r")
            .disabled(actions == nil)

            Divider()

            Button("Select All Candidates") {
                actions?.selectAll()
            }
            .keyboardShortcut("a", modifiers: [.command, .shift])
            .disabled(actions == nil)

            Button("Clear Selection") {
                actions?.clearSelection()
            }
            .keyboardShortcut(.delete, modifiers: [.command, .shift])
            .disabled(actions == nil)

            Divider()

            Button("Ask AI") {
                actions?.askAI()
            }
            .keyboardShortcut("i", modifiers: [.command, .shift])
            .disabled(actions == nil)
        }
    }
}
