import CleanMacCore
import SwiftUI

struct ContentView: View {
    @StateObject private var store: CleaningStore
    @State private var selection: SidebarSection?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(AppLanguage.storageKey) private var appLanguageRaw = AppLanguage.system.rawValue
    @AppStorage("aiExecutable") private var aiExecutable = "/usr/bin/env"
    @AppStorage("aiArguments") private var aiArguments = "codex exec"

    init(store: CleaningStore? = nil, initialSelection: SidebarSection = .diskOverview) {
        let preference = AppLanguage(storedRawValue: UserDefaults.standard.string(forKey: AppLanguage.storageKey))
        _store = StateObject(wrappedValue: store ?? CleaningStore(language: preference.resolved()))
        _selection = State(initialValue: initialSelection)
    }

    var body: some View {
        VStack(spacing: 0) {
            CleanMacAppTitleBar(title: "CleanMac - \((selection ?? .diskOverview).title(language: resolvedLanguage))")

            HStack(spacing: 0) {
                SidebarView(selection: $selection, store: store, language: resolvedLanguage)

                Group {
                    switch (selection ?? .diskOverview).contentTarget {
                    case .scan:
                        ScanView(
                            store: store,
                            language: resolvedLanguage,
                            openResults: {
                                selection = .cleanUp
                            }
                        )
                    case .uninstaller:
                        AppUninstallerView(
                            store: store,
                            language: resolvedLanguage,
                            openResults: {
                                selection = .cleanUp
                            }
                        )
                    case .results:
                        ResultsView(store: store, language: resolvedLanguage)
                    case .aiReview:
                        AIReviewView(
                            store: store,
                            aiExecutable: $aiExecutable,
                            aiArguments: $aiArguments,
                            language: resolvedLanguage
                        )
                    case .settings:
                        SettingsView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .id(selection ?? .diskOverview)
                .transition(.cleanMacPage)
                .animation(CleanMacMotion.allowed(reduceMotion, CleanMacMotion.page), value: selection)
            }
        }
        .tint(CleanMacTheme.accent)
        .buttonStyle(CleanMacRaisedButtonStyle())
        .background(CleanMacTheme.paper)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(CleanMacTheme.ink, lineWidth: 3)
        }
        .shadow(color: Color.black.opacity(0.14), radius: 18, x: 0, y: 14)
        .padding(1)
        .frame(minWidth: 1_020, minHeight: 660)
        .focusedSceneValue(\.cleanerActions, CleanerActions(
            scan: {
                store.scan()
                selection = .cleanUp
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
