import AppKit
import CleanMacCore
import SwiftUI

enum CleanMacTheme {
    static let accent = Color(red: 0.08, green: 0.46, blue: 0.68)
    static let mint = Color(red: 0.08, green: 0.58, blue: 0.45)
    static let amber = Color.orange
    static let danger = Color.red
    static let neutral = Color.secondary

    static let panelRadius: CGFloat = 8
    static let compactSpacing: CGFloat = 10
    static let sectionSpacing: CGFloat = 16

    static var panelShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: panelRadius, style: .continuous)
    }

    static func sectionTint(_ section: SidebarSection) -> Color {
        switch section {
        case .scan: accent
        case .uninstaller: mint
        case .results: Color.indigo
        case .aiReview: Color.pink
        }
    }

    static func riskColor(_ risk: DeletionRisk) -> Color {
        switch risk {
        case .usuallySafe: mint
        case .reviewRecommended: amber
        case .beCareful: danger
        }
    }

    static func protectionColor(_ protection: DeletionProtection) -> Color {
        switch protection {
        case .allowed: mint
        case .requiresReview: amber
        case .blocked: danger
        }
    }

    static func permissionColor(_ status: SystemPermissionStatus) -> Color {
        switch status {
        case .granted: mint
        case .needsAttention: amber
        case .unavailable: neutral
        }
    }

    static func statusColor(_ status: CleaningStatus) -> Color {
        switch status {
        case .ready, .candidatesFound, .movedToTrash, .aiReviewFinished:
            mint
        case .scanning, .movingToTrash, .askingAI:
            accent
        case .scanFailed, .cleanupFailed, .aiReviewFailed:
            danger
        }
    }

    static func statusSymbol(_ status: CleaningStatus) -> String {
        switch status {
        case .ready:
            "checkmark.circle"
        case .scanning:
            "magnifyingglass"
        case .candidatesFound:
            "list.bullet.rectangle"
        case .scanFailed:
            "exclamationmark.triangle"
        case .movingToTrash:
            "trash"
        case .movedToTrash:
            "checkmark.seal"
        case .cleanupFailed:
            "xmark.octagon"
        case .askingAI:
            "sparkles"
        case .aiReviewFinished:
            "sparkles"
        case .aiReviewFailed:
            "exclamationmark.triangle"
        }
    }
}

enum CleanMacMotion {
    static let quick = Animation.easeInOut(duration: 0.18)
    static let settle = Animation.spring(response: 0.28, dampingFraction: 0.86)
    static let pulse = Animation.easeInOut(duration: 0.9).repeatForever(autoreverses: true)

    static func allowed(_ reduceMotion: Bool, _ animation: Animation) -> Animation? {
        reduceMotion ? nil : animation
    }
}

extension AnyTransition {
    static var cleanMacPage: AnyTransition {
        .opacity.combined(with: .scale(scale: 0.985, anchor: .center))
    }

    static var cleanMacInsert: AnyTransition {
        .opacity.combined(with: .move(edge: .top))
    }
}

struct CleanMacPage<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CleanMacTheme.sectionSpacing) {
                content
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.35))
    }
}

struct CleanMacPanel<Content: View>: View {
    var padding: CGFloat = 16
    let content: Content

    init(padding: CGFloat = 16, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background(.regularMaterial, in: CleanMacTheme.panelShape)
            .overlay {
                CleanMacTheme.panelShape
                    .strokeBorder(.primary.opacity(0.08), lineWidth: 1)
            }
    }
}

struct CleanMacHeroHeader<Actions: View>: View {
    var title: String
    var subtitle: String
    var symbolName: String
    var tint: Color
    var isActive = false
    let actions: Actions

    init(
        title: String,
        subtitle: String,
        symbolName: String,
        tint: Color,
        isActive: Bool = false,
        @ViewBuilder actions: () -> Actions = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.symbolName = symbolName
        self.tint = tint
        self.isActive = isActive
        self.actions = actions()
    }

    var body: some View {
        CleanMacPanel {
            HStack(alignment: .center, spacing: 14) {
                CleanMacPulseIcon(symbolName: symbolName, tint: tint, isActive: isActive)
                    .font(.title2)
                    .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 12)

                actions
            }
        }
    }
}

struct CleanMacSectionHeader: View {
    var title: String
    var symbolName: String
    var tint: Color = CleanMacTheme.accent

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbolName)
                .foregroundStyle(tint)
                .frame(width: 18)
            Text(title)
                .font(.headline)
            Spacer()
        }
    }
}

struct MetricTileView: View {
    var title: String
    var value: String
    var symbolName: String
    var tint: Color
    var isActive = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 10) {
            CleanMacPulseIcon(symbolName: symbolName, tint: tint, isActive: isActive)
                .font(.title3)
                .frame(width: 34, height: 34)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(value)
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .monospacedDigit()
                    .contentTransition(.numericText())
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(minWidth: 150, maxWidth: .infinity, minHeight: 78)
        .background(.regularMaterial, in: CleanMacTheme.panelShape)
        .overlay {
            CleanMacTheme.panelShape
                .strokeBorder(tint.opacity(0.18), lineWidth: 1)
        }
        .animation(CleanMacMotion.allowed(reduceMotion, CleanMacMotion.settle), value: value)
    }
}

struct StatusBadge: View {
    var text: String
    var symbolName: String?
    var tint: Color
    var isActive = false

    var body: some View {
        HStack(spacing: 5) {
            if let symbolName {
                Image(systemName: symbolName)
                    .imageScale(.small)
            }
            Text(text)
                .lineLimit(1)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .foregroundStyle(tint)
        .background(tint.opacity(isActive ? 0.16 : 0.10), in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(tint.opacity(0.24), lineWidth: 1)
        }
    }
}

struct CleanMacEmptyState: View {
    var title: String
    var symbolName: String
    var tint: Color = CleanMacTheme.accent

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: symbolName)
                .font(.system(size: 34, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 58, height: 58)
                .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(28)
    }
}

struct CleanMacProgressState: View {
    var title: String
    var symbolName: String
    var tint: Color = CleanMacTheme.accent

    var body: some View {
        VStack(spacing: 12) {
            CleanMacPulseIcon(symbolName: symbolName, tint: tint, isActive: true)
                .font(.title2)
                .frame(width: 54, height: 54)
            ProgressView()
                .controlSize(.small)
            Text(title)
                .font(.callout)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(28)
    }
}

struct CleanMacURLList: View {
    var urls: [URL]
    var tint: Color
    var remove: (URL) -> Void
    var language: ResolvedLanguage

    var body: some View {
        VStack(spacing: 0) {
            if urls.isEmpty {
                CleanMacEmptyState(
                    title: L10n.folderCount(0, language: language),
                    symbolName: "folder",
                    tint: tint
                )
                .frame(minHeight: 120)
            } else {
                ForEach(urls, id: \.self) { url in
                    HStack(spacing: 10) {
                        Image(systemName: "folder")
                            .foregroundStyle(tint)
                            .frame(width: 18)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent)
                                .lineLimit(1)
                            Text(url.path)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        Spacer()
                        Button {
                            remove(url)
                        } label: {
                            Image(systemName: "minus.circle")
                        }
                        .buttonStyle(.borderless)
                        .help(L10n.text(.remove, language: language))
                    }
                    .padding(.vertical, 9)
                    .transition(.cleanMacInsert)

                    if url != urls.last {
                        Divider()
                    }
                }
            }
        }
    }
}

struct CleanMacPulseIcon: View {
    var symbolName: String
    var tint: Color
    var isActive: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pulsing = false

    var body: some View {
        Image(systemName: symbolName)
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(tint.opacity(isActive ? 0.16 : 0.11), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .scaleEffect(pulsing ? 1.06 : 1.0)
            .animation(CleanMacMotion.allowed(reduceMotion, CleanMacMotion.pulse), value: pulsing)
            .onAppear(perform: updatePulse)
            .onChange(of: isActive) { _, _ in updatePulse() }
            .onChange(of: reduceMotion) { _, _ in updatePulse() }
    }

    private func updatePulse() {
        guard isActive, !reduceMotion else {
            pulsing = false
            return
        }
        pulsing = true
    }
}
