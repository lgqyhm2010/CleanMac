import CleanMacCore
import SwiftUI

struct ContentView: View {
    @StateObject private var store: CleaningStore
    @State private var selection: SidebarSection?
    private let languageOverride: ResolvedLanguage?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @AppStorage(AppLanguage.storageKey) private var appLanguageRaw = AppLanguage.system.rawValue

    init(
        store: CleaningStore? = nil,
        initialSelection: SidebarSection = .diskOverview,
        languageOverride: ResolvedLanguage? = nil
    ) {
        self.languageOverride = languageOverride
        let preference = AppLanguage(storedRawValue: UserDefaults.standard.string(forKey: AppLanguage.storageKey))
        let initialLanguage = languageOverride ?? preference.resolved()
        _store = StateObject(wrappedValue: store ?? CleaningStore(language: initialLanguage))
        _selection = State(initialValue: initialSelection)
    }

    var body: some View {
        VStack(spacing: 0) {
            CleanMacAppTitleBar(
                title: L10n.windowTitle(
                    (selection ?? .diskOverview).title(language: resolvedLanguage),
                    language: resolvedLanguage
                ),
                language: resolvedLanguage,
                openSettings: { selection = .settings }
            )

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
                            },
                            openAIReview: {
                                selection = .aiReview
                            },
                            openSettings: {
                                selection = .settings
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
        .onChange(of: resolvedLanguage) { _, newLanguage in
            store.updateDefaultAIQuestionIfNeeded(language: newLanguage)
        }
    }

    private var resolvedLanguage: ResolvedLanguage {
        languageOverride ?? AppLanguage(storedRawValue: appLanguageRaw).resolved()
    }
}
