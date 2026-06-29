import CleanMacCore
import SwiftUI

struct PermissionGuideView: View {
    enum DisplayStyle {
        case compact
        case detailed
    }

    var guide: SystemPermissionGuide
    var language: ResolvedLanguage
    var displayStyle: DisplayStyle = .compact

    @Environment(\.openURL) private var openURL

    var body: some View {
        CleanMacPanel(padding: 14, tint: statusColor) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    CleanMacFeatureImage(
                        asset: .permissionShield,
                        tint: statusColor,
                        isActive: guide.status == .needsAttention
                    )
                    .frame(width: 42, height: 42)

                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Text(L10n.permissionTitle(guide, language: language))
                                .font(.headline)

                            StatusBadge(
                                text: L10n.permissionStatusName(guide.status, language: language),
                                symbolName: statusSymbolName,
                                tint: statusColor,
                                isActive: guide.status == .needsAttention
                            )
                        }

                        Text(L10n.permissionExplanation(guide, language: language))
                            .font(.callout)
                            .foregroundStyle(CleanMacTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 8)

                    if let settingsURL = guide.settingsURL {
                        Button {
                            openURL(settingsURL)
                        } label: {
                            Label(L10n.text(.openSettings, language: language), systemImage: "gearshape")
                        }
                        .buttonStyle(CleanMacRaisedButtonStyle(tint: statusColor))
                    }
                }

                if displayStyle == .detailed {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(Array(L10n.permissionInstructions(guide, language: language).enumerated()), id: \.offset) { index, instruction in
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                Text("\(index + 1).")
                                    .foregroundStyle(CleanMacTheme.secondaryText)
                                    .monospacedDigit()
                                Text(instruction)
                                    .foregroundStyle(CleanMacTheme.secondaryText)
                            }
                            .font(.caption)
                        }
                    }
                }
            }
        }
    }

    private var statusColor: Color {
        CleanMacTheme.permissionColor(guide.status)
    }

    private var statusSymbolName: String {
        switch guide.status {
        case .granted: "checkmark.shield"
        case .needsAttention: "lock.shield"
        case .unavailable: "questionmark.folder"
        }
    }
}
