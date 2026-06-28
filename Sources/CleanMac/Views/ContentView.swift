import CleanMacCore
import SwiftUI

struct ContentView: View {
    @StateObject private var store: CleaningStore
    @State private var selection: SidebarSection? = .scan
    @AppStorage(AppLanguage.storageKey) private var appLanguageRaw = AppLanguage.system.rawValue
    @AppStorage("aiExecutable") private var aiExecutable = "/usr/bin/env"
    @AppStorage("aiArguments") private var aiArguments = "codex exec"

    init() {
        let preference = AppLanguage(storedRawValue: UserDefaults.standard.string(forKey: AppLanguage.storageKey))
        _store = StateObject(wrappedValue: CleaningStore(language: preference.resolved()))
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection, store: store, language: resolvedLanguage)
        } detail: {
            Group {
                switch selection ?? .scan {
                case .scan:
                    ScanView(store: store, language: resolvedLanguage)
                case .results:
                    ResultsView(store: store, language: resolvedLanguage)
                case .aiReview:
                    AIReviewView(
                        store: store,
                        aiExecutable: $aiExecutable,
                        aiArguments: $aiArguments,
                        language: resolvedLanguage
                    )
                }
            }
            .navigationTitle((selection ?? .scan).title(language: resolvedLanguage))
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    store.scan()
                    selection = .results
                } label: {
                    Label(L10n.text(.scan, language: resolvedLanguage), systemImage: "arrow.clockwise")
                }
                .disabled(store.isScanning)

                Button {
                    store.selectAll()
                } label: {
                    Label(L10n.text(.selectAll, language: resolvedLanguage), systemImage: "checklist.checked")
                }
                .disabled(store.candidates.isEmpty)

                Button {
                    store.askAI(executable: aiExecutable, argumentsText: aiArguments)
                    selection = .aiReview
                } label: {
                    Label(L10n.text(.askAI, language: resolvedLanguage), systemImage: "sparkles")
                }
                .disabled(store.selectedSummary.selectedCount == 0 || store.isReviewingWithAI)
            }
        }
        .focusedSceneValue(\.cleanerActions, CleanerActions(
            scan: {
                store.scan()
                selection = .results
            },
            selectAll: {
                store.selectAll()
            },
            clearSelection: {
                store.clearSelection()
            },
            askAI: {
                store.askAI(executable: aiExecutable, argumentsText: aiArguments)
                selection = .aiReview
            }
        ))
        .onChange(of: resolvedLanguage) { _, newLanguage in
            store.updateDefaultAIQuestionIfNeeded(language: newLanguage)
        }
    }

    private var resolvedLanguage: ResolvedLanguage {
        AppLanguage(storedRawValue: appLanguageRaw).resolved()
    }
}
