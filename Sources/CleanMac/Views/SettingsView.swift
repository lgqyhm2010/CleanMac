import CleanMacCore
import SwiftUI

struct SettingsView: View {
    @AppStorage(AppLanguage.storageKey) private var appLanguageRaw = AppLanguage.system.rawValue
    @AppStorage("aiExecutable") private var aiExecutable = "/usr/bin/env"
    @AppStorage("aiArguments") private var aiArguments = "codex exec"

    var body: some View {
        TabView {
            VStack(spacing: 16) {
                CleanMacHeroHeader(
                    title: L10n.text(.aiCLI, language: resolvedLanguage),
                    subtitle: L10n.text(.command, language: resolvedLanguage),
                    symbolName: "sparkles",
                    tint: CleanMacTheme.sectionTint(.aiReview)
                )

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
                .formStyle(.grouped)
            }
            .padding(20)
            .tabItem {
                Label(L10n.text(.aiCLI, language: resolvedLanguage), systemImage: "sparkles")
            }

            VStack(spacing: 16) {
                CleanMacHeroHeader(
                    title: L10n.text(.permissions, language: resolvedLanguage),
                    subtitle: L10n.permissionStatusName(fullDiskAccessGuide.status, language: resolvedLanguage),
                    symbolName: "lock.shield",
                    tint: CleanMacTheme.permissionColor(fullDiskAccessGuide.status)
                )

                PermissionGuideView(
                    guide: fullDiskAccessGuide,
                    language: resolvedLanguage,
                    displayStyle: .detailed
                )

                Spacer(minLength: 0)
            }
            .padding(20)
            .tabItem {
                Label(L10n.text(.permissions, language: resolvedLanguage), systemImage: "lock.shield")
            }
        }
        .tint(CleanMacTheme.accent)
        .frame(width: 640, height: 420)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.35))
    }

    private var resolvedLanguage: ResolvedLanguage {
        AppLanguage(storedRawValue: appLanguageRaw).resolved()
    }

    private var fullDiskAccessGuide: SystemPermissionGuide {
        .fullDiskAccess()
    }
}
