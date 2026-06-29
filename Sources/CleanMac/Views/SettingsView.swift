import CleanMacCore
import SwiftUI

struct SettingsView: View {
    @AppStorage(AppLanguage.storageKey) private var appLanguageRaw = AppLanguage.system.rawValue
    @AppStorage("aiExecutable") private var aiExecutable = "/usr/bin/env"
    @AppStorage("aiArguments") private var aiArguments = "codex exec"

    var body: some View {
        CleanMacPage(accent: CleanMacTheme.purple) {
            CleanMacHeroHeader(
                title: L10n.text(.settings, language: resolvedLanguage),
                subtitle: "\(L10n.text(.aiCLI, language: resolvedLanguage)) / \(L10n.text(.permissions, language: resolvedLanguage))",
                symbolName: "gearshape",
                asset: .permissionShield,
                tint: CleanMacTheme.purple
            )

            CleanMacPanel(tint: CleanMacTheme.sectionTint(.aiReview)) {
                VStack(alignment: .leading, spacing: 12) {
                    CleanMacSectionHeader(
                        title: L10n.text(.aiCLI, language: resolvedLanguage),
                        symbolName: "sparkles",
                        tint: CleanMacTheme.sectionTint(.aiReview)
                    )

                    languageMenu

                    TextField(L10n.text(.executable, language: resolvedLanguage), text: $aiExecutable)
                        .cleanMacTextField(tint: CleanMacTheme.sectionTint(.aiReview))

                    TextField(L10n.text(.arguments, language: resolvedLanguage), text: $aiArguments)
                        .cleanMacTextField(tint: CleanMacTheme.sectionTint(.aiReview))
                }
            }

            PermissionGuideView(
                guide: fullDiskAccessGuide,
                language: resolvedLanguage,
                displayStyle: .detailed
            )
        }
        .tint(CleanMacTheme.accent)
        .buttonStyle(CleanMacRaisedButtonStyle())
        .foregroundStyle(CleanMacTheme.ink)
    }

    @ViewBuilder
    private var languageMenu: some View {
        Menu {
            ForEach(AppLanguage.allCases) { preference in
                Button {
                    appLanguageRaw = preference.rawValue
                } label: {
                    if preference.rawValue == appLanguageRaw {
                        Label(
                            L10n.languagePreferenceName(preference, language: resolvedLanguage),
                            systemImage: "checkmark"
                        )
                    } else {
                        Text(L10n.languagePreferenceName(preference, language: resolvedLanguage))
                    }
                }
            }
        } label: {
            HStack(spacing: 10) {
                Text(L10n.text(.appLanguage, language: resolvedLanguage))
                    .foregroundStyle(CleanMacTheme.ink)

                Spacer(minLength: 12)

                Text(selectedLanguageName)
                    .foregroundStyle(CleanMacTheme.secondaryText)
                    .lineLimit(1)

                Image(systemName: "chevron.up.chevron.down")
                    .imageScale(.small)
            }
        }
        .buttonStyle(CleanMacRaisedButtonStyle(tint: CleanMacTheme.purple))
    }

    private var selectedLanguageName: String {
        let preference = AppLanguage(storedRawValue: appLanguageRaw)
        return L10n.languagePreferenceName(preference, language: resolvedLanguage)
    }

    private var resolvedLanguage: ResolvedLanguage {
        AppLanguage(storedRawValue: appLanguageRaw).resolved()
    }

    private var fullDiskAccessGuide: SystemPermissionGuide {
        .fullDiskAccess()
    }
}
