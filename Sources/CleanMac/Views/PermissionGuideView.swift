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
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: statusSymbolName)
                    .font(.title3)
                    .foregroundStyle(statusColor)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(L10n.permissionTitle(guide, language: language))
                            .font(.headline)

                        Text(L10n.permissionStatusName(guide.status, language: language))
                            .font(.caption)
                            .foregroundStyle(statusColor)
                    }

                    Text(L10n.permissionExplanation(guide, language: language))
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 8)

                if let settingsURL = guide.settingsURL {
                    Button {
                        openURL(settingsURL)
                    } label: {
                        Label(L10n.text(.openSettings, language: language), systemImage: "gearshape")
                    }
                }
            }

            if displayStyle == .detailed {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(Array(L10n.permissionInstructions(guide, language: language).enumerated()), id: \.offset) { index, instruction in
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("\(index + 1).")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                            Text(instruction)
                                .foregroundStyle(.secondary)
                        }
                        .font(.caption)
                    }
                }
            }
        }
        .padding(14)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }

    private var statusColor: Color {
        switch guide.status {
        case .granted: .green
        case .needsAttention: .orange
        case .unavailable: .secondary
        }
    }

    private var statusSymbolName: String {
        switch guide.status {
        case .granted: "checkmark.shield"
        case .needsAttention: "lock.shield"
        case .unavailable: "questionmark.folder"
        }
    }
}
