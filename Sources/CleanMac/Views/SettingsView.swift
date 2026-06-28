import CleanMacCore
import SwiftUI

struct SettingsView: View {
    @AppStorage(AppLanguage.storageKey) private var appLanguageRaw = AppLanguage.system.rawValue
    @AppStorage("aiExecutable") private var aiExecutable = "/usr/bin/env"
    @AppStorage("aiArguments") private var aiArguments = "codex exec"

    var body: some View {
        TabView {
            Form {
                Picker(L10n.text(.appLanguage, language: resolvedLanguage), selection: $appLanguageRaw) {
                    ForEach(AppLanguage.allCases) { preference in
                        Text(L10n.languagePreferenceName(preference, language: resolvedLanguage))
                            .tag(preference.rawValue)
                    }
                }

                TextField(L10n.text(.executable, language: resolvedLanguage), text: $aiExecutable)
                TextField(L10n.text(.arguments, language: resolvedLanguage), text: $aiArguments)
            }
            .padding(20)
            .tabItem {
                Label(L10n.text(.aiCLI, language: resolvedLanguage), systemImage: "sparkles")
            }

            Form {
                PermissionGuideView(
                    guide: .fullDiskAccess(),
                    language: resolvedLanguage,
                    displayStyle: .detailed
                )
            }
            .padding(20)
            .tabItem {
                Label(L10n.text(.permissions, language: resolvedLanguage), systemImage: "lock.shield")
            }
        }
        .frame(width: 620, height: 360)
    }

    private var resolvedLanguage: ResolvedLanguage {
        AppLanguage(storedRawValue: appLanguageRaw).resolved()
    }
}
