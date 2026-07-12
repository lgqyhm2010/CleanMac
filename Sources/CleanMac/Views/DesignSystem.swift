import AppKit
import CleanMacCore
import SwiftUI

private extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xff) / 255.0,
            green: Double((hex >> 8) & 0xff) / 255.0,
            blue: Double(hex & 0xff) / 255.0
        )
    }
}

enum CleanMacTheme {
    static let ink = Color(hex: 0x241F36)
    static let paper = Color(hex: 0xFFFDF6)
    static let warmPane = Color(hex: 0xFBF6EB)
    static let chrome = Color(hex: 0xEFE7D6)
    static let desk = Color(hex: 0xEDF1F4)
    static let shadow = Color(hex: 0xE7DECD)
    static let titlebar = paper
    static let sidebar = paper
    static let sidebarBorder = ink
    static let sidebarDivider = ink.opacity(0.12)
    static let sidebarSelectedFill = Color(hex: 0xEAF2FF)
    static let sidebarText = secondaryText
    static let sidebarPrimaryText = ink
    static let sidebarRowText = ink
    static let secondaryText = Color(hex: 0x706B82)

    static let accent = Color(hex: 0x5DAEE7)
    static let mint = Color(hex: 0x74C6A6)
    static let amber = Color(hex: 0xF6C94E)
    static let purple = Color(hex: 0xA685DF)
    static let pink = Color(hex: 0xEF96B5)
    static let peach = Color(hex: 0xF2A67F)
    static let salmon = Color(hex: 0xF5B896)
    static let slate = Color(hex: 0xA8B8D9)
    static let danger = Color(hex: 0xEA6A70)
    static let neutral = Color(hex: 0x706B82)

    static let panelRadius: CGFloat = 14
    static let compactSpacing: CGFloat = 10
    static let sectionSpacing: CGFloat = 16
    static let outlineWidth: CGFloat = 2.5

    static var panelShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: panelRadius, style: .continuous)
    }

    static func sectionTint(_ section: SidebarSection) -> Color {
        switch section {
        case .diskOverview: accent
        case .speedUp: peach
        case .cleanUp: mint
        case .manageSpace: purple
        case .duplicates: amber
        case .uninstaller: pink
        case .analyzeSpace: mint
        case .aiReview: purple
        case .settings: neutral
        }
    }

    /// Single source of truth for candidate-category colors, shared by the
    /// results table and the disk-overview segment bar.
    static func categoryColor(_ category: CandidateCategory) -> Color {
        switch category {
        case .cache: accent
        case .logs: purple
        case .downloads: amber
        case .trash: danger
        case .temporary: peach
        case .developer: pink
        case .largeFile: salmon
        case .application: mint
        case .applicationSupport: slate
        case .other: neutral
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
    static let page = Animation.easeOut(duration: 0.25)
    static let settle = Animation.spring(response: 0.28, dampingFraction: 0.86)
    static let pulse = Animation.easeInOut(duration: 0.9).repeatForever(autoreverses: true)
    static let float = Animation.easeInOut(duration: 3.0).repeatForever(autoreverses: true)
    static let beam = Animation.linear(duration: 1.4).repeatForever(autoreverses: false)

    static func allowed(_ reduceMotion: Bool, _ animation: Animation) -> Animation? {
        reduceMotion ? nil : animation
    }
}

private struct CleanMacPageTransitionModifier: ViewModifier {
    var offsetY: CGFloat
    var opacity: Double

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .offset(y: offsetY)
    }
}

extension AnyTransition {
    static var cleanMacPage: AnyTransition {
        .modifier(
            active: CleanMacPageTransitionModifier(offsetY: 12, opacity: 0),
            identity: CleanMacPageTransitionModifier(offsetY: 0, opacity: 1)
        )
    }

    static var cleanMacInsert: AnyTransition {
        .opacity.combined(with: .move(edge: .top))
    }
}

enum CleanMacIllustrationAsset: String {
    case mascot = "cleanmac-mascot"
    case diskOverview = "feature-disk-overview"
    case speedUp = "feature-speed-up"
    case cleanupTrash = "feature-cleanup-trash"
    case manageSpace = "feature-manage-space"
    case duplicates = "feature-duplicates"
    case appUninstall = "feature-app-uninstall"
    case spaceAnalysis = "feature-space-analysis"
    case aiReview = "feature-ai-review"
    case permissionShield = "feature-permission-shield"
    case settings = "feature-settings"
}

struct CleanMacPage<Content: View>: View {
    var accent: Color = CleanMacTheme.accent
    let content: Content

    init(accent: Color = CleanMacTheme.accent, @ViewBuilder content: () -> Content) {
        self.accent = accent
        self.content = content()
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: CleanMacTheme.sectionSpacing) {
                content
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background {
            CleanMacPageBackground(accent: accent)
        }
        .foregroundStyle(CleanMacTheme.ink)
    }
}

struct CleanMacPageBackground: View {
    var accent: Color = CleanMacTheme.accent

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                CleanMacTheme.warmPane
                CleanMacPaperTexture(accent: accent)

                CleanMacSparkle(position: CGPoint(x: proxy.size.width * 0.86, y: proxy.size.height * 0.18))
                CleanMacSparkle(position: CGPoint(x: proxy.size.width * 0.68, y: proxy.size.height * 0.72))
                CleanMacSparkle(position: CGPoint(x: proxy.size.width * 0.16, y: proxy.size.height * 0.30))
            }
            .ignoresSafeArea()
        }
    }
}

private struct CleanMacPaperTexture: View {
    var accent: Color

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                Path { path in
                    let spacing: CGFloat = 28
                    var x: CGFloat = -proxy.size.height
                    while x < proxy.size.width {
                        path.move(to: CGPoint(x: x, y: proxy.size.height))
                        path.addLine(to: CGPoint(x: x + proxy.size.height, y: 0))
                        x += spacing
                    }
                }
                .stroke(CleanMacTheme.ink.opacity(0.035), style: StrokeStyle(lineWidth: 1, dash: [5, 12]))

                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(accent.opacity(0.08))
                    .frame(width: min(320, proxy.size.width * 0.36), height: 10)
                    .offset(x: proxy.size.width * 0.60, y: 28)

                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(CleanMacTheme.peach.opacity(0.10))
                    .frame(width: min(260, proxy.size.width * 0.30), height: 10)
                    .offset(x: proxy.size.width * 0.10, y: max(160, proxy.size.height - 58))
            }
        }
    }
}

struct CleanMacAppTitleBar: View {
    var title: String
    var language: ResolvedLanguage
    var openSettings: () -> Void = {}

    var body: some View {
        ZStack {
            CleanMacTheme.titlebar

            HStack(spacing: 16) {
                HStack(spacing: 8) {
                    TrafficLightDot(color: Color(hex: 0xFF6257))
                    TrafficLightDot(color: Color(hex: 0xFDBC2E))
                    TrafficLightDot(color: Color(hex: 0x29C940))
                }
                .frame(width: 76, alignment: .leading)

                HStack(spacing: 9) {
                    CleanMacFeatureImage(asset: .mascot, tint: CleanMacTheme.accent)
                        .frame(width: 30, height: 30)
                    Text("CleanMac")
                        .font(.title3.weight(.black))
                        .foregroundStyle(CleanMacTheme.ink)
                        .lineLimit(1)
                }

                Spacer(minLength: 24)

                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CleanMacTheme.secondaryText)
                    .lineLimit(1)

                Spacer(minLength: 24)

                HStack(spacing: 18) {
                    Button(action: openSettings) {
                        Label(L10n.text(.settings, language: language), systemImage: "gearshape")
                    }
                    .buttonStyle(.plain)

                    Button(action: openHelp) {
                        Label(L10n.text(.help, language: language), systemImage: "questionmark.circle")
                    }
                    .buttonStyle(.plain)
                }
                .font(.callout.weight(.semibold))
                .foregroundStyle(CleanMacTheme.ink)
            }
            .padding(.horizontal, 18)
        }
        .frame(height: 48)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(CleanMacTheme.ink)
                .frame(height: 1.5)
        }
    }

    private func openHelp() {
        guard let url = URL(string: "https://github.com/lgqyhm2010/CleanMac") else { return }
        NSWorkspace.shared.open(url)
    }
}

private struct TrafficLightDot: View {
    var color: Color

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 12, height: 12)
            .overlay {
                Circle()
                    .strokeBorder(CleanMacTheme.ink.opacity(0.32), lineWidth: 1)
            }
    }
}

private struct CleanMacSparkle: View {
    var position: CGPoint

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(CleanMacTheme.ink.opacity(0.18))
            .opacity(0.22)
            .position(position)
    }
}

struct CleanMacPanel<Content: View>: View {
    var padding: CGFloat = 16
    var tint: Color = CleanMacTheme.accent
    let content: Content

    init(padding: CGFloat = 16, tint: Color = CleanMacTheme.accent, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.tint = tint
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .foregroundStyle(CleanMacTheme.ink)
            .background {
                CleanMacTheme.panelShape
                    .fill(CleanMacTheme.paper)
                    .shadow(color: CleanMacTheme.shadow, radius: 0, x: 0, y: 5)
            }
            .overlay {
                CleanMacTheme.panelShape
                    .strokeBorder(CleanMacTheme.ink, lineWidth: CleanMacTheme.outlineWidth)
            }
    }
}

private struct CleanMacTextFieldChrome: ViewModifier {
    var tint: Color

    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .font(.body)
            .foregroundStyle(CleanMacTheme.ink)
            .tint(tint)
            .padding(.horizontal, 10)
            .frame(minHeight: 34, alignment: .center)
            .background(CleanMacTheme.paper, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(tint.opacity(0.72), lineWidth: 1.5)
            }
    }
}

extension View {
    func cleanMacTextField(tint: Color = CleanMacTheme.accent) -> some View {
        modifier(CleanMacTextFieldChrome(tint: tint))
    }
}

struct CleanMacHeroHeader<Actions: View>: View {
    var title: String
    var subtitle: String
    var symbolName: String
    var asset: CleanMacIllustrationAsset?
    var tint: Color
    var isActive = false
    let actions: Actions

    init(
        title: String,
        subtitle: String,
        symbolName: String,
        asset: CleanMacIllustrationAsset? = nil,
        tint: Color,
        isActive: Bool = false,
        @ViewBuilder actions: () -> Actions = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.symbolName = symbolName
        self.asset = asset
        self.tint = tint
        self.isActive = isActive
        self.actions = actions()
    }

    var body: some View {
        CleanMacPanel(tint: tint) {
            HStack(alignment: .center, spacing: 14) {
                if let asset {
                    CleanMacFeatureImage(asset: asset, tint: tint, isActive: isActive)
                        .frame(width: 50, height: 50)
                } else {
                    CleanMacPulseIcon(symbolName: symbolName, tint: tint, isActive: isActive)
                        .font(.title2)
                        .frame(width: 42, height: 42)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title3.weight(.semibold))
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.callout)
                        .foregroundStyle(CleanMacTheme.secondaryText)
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
                .symbolRenderingMode(.hierarchical)
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
    var asset: CleanMacIllustrationAsset?
    var tint: Color
    var isActive = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        title: String,
        value: String,
        symbolName: String,
        asset: CleanMacIllustrationAsset? = nil,
        tint: Color,
        isActive: Bool = false
    ) {
        self.title = title
        self.value = value
        self.symbolName = symbolName
        self.asset = asset
        self.tint = tint
        self.isActive = isActive
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                if let asset {
                    CleanMacFeatureImage(asset: asset, tint: tint, isActive: isActive)
                        .frame(width: 38, height: 38)
                } else {
                    CleanMacPulseIcon(symbolName: symbolName, tint: tint, isActive: isActive)
                        .font(.title3)
                        .frame(width: 34, height: 34)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CleanMacTheme.secondaryText)
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

            if isActive {
                CleanMacProgressBeam(tint: tint)
                    .frame(height: 8)
                    .transition(.opacity)
            }
        }
        .padding(14)
        .frame(minWidth: 150, maxWidth: .infinity, minHeight: 86)
        .background {
            CleanMacTheme.panelShape
                .fill(CleanMacTheme.paper)
                .shadow(color: CleanMacTheme.shadow, radius: 0, x: 0, y: 4)
        }
        .overlay {
            CleanMacTheme.panelShape
                .strokeBorder(CleanMacTheme.ink, lineWidth: 2)
        }
        .animation(CleanMacMotion.allowed(reduceMotion, CleanMacMotion.settle), value: value)
        .animation(CleanMacMotion.allowed(reduceMotion, CleanMacMotion.quick), value: isActive)
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
        .foregroundStyle(CleanMacTheme.ink)
        .background(tint.opacity(isActive ? 0.34 : 0.20), in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(CleanMacTheme.ink, lineWidth: 1.5)
        }
    }
}

struct CleanMacEmptyState: View {
    var title: String
    var symbolName: String
    var asset: CleanMacIllustrationAsset?
    var tint: Color = CleanMacTheme.accent

    init(
        title: String,
        symbolName: String,
        asset: CleanMacIllustrationAsset? = nil,
        tint: Color = CleanMacTheme.accent
    ) {
        self.title = title
        self.symbolName = symbolName
        self.asset = asset
        self.tint = tint
    }

    var body: some View {
        VStack(spacing: 10) {
            if let asset {
                CleanMacFeatureImage(asset: asset, tint: tint, isActive: false)
                    .frame(width: 72, height: 72)
            } else {
                Image(systemName: symbolName)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 58, height: 58)
                    .background(tint.opacity(0.18), in: CleanMacTheme.panelShape)
                    .overlay {
                        CleanMacTheme.panelShape
                            .strokeBorder(CleanMacTheme.ink, lineWidth: 2)
                    }
            }

            Text(title)
                .font(.headline)
                .foregroundStyle(CleanMacTheme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(28)
    }
}

struct CleanMacProgressState: View {
    var title: String
    var symbolName: String
    var asset: CleanMacIllustrationAsset?
    var tint: Color = CleanMacTheme.accent

    init(
        title: String,
        symbolName: String,
        asset: CleanMacIllustrationAsset? = nil,
        tint: Color = CleanMacTheme.accent
    ) {
        self.title = title
        self.symbolName = symbolName
        self.asset = asset
        self.tint = tint
    }

    var body: some View {
        VStack(spacing: 12) {
            if let asset {
                CleanMacFeatureImage(asset: asset, tint: tint, isActive: true)
                    .frame(width: 76, height: 76)
            } else {
                CleanMacPulseIcon(symbolName: symbolName, tint: tint, isActive: true)
                    .font(.title2)
                    .frame(width: 54, height: 54)
            }

            CleanMacProgressBeam(tint: tint)
                .frame(width: 180, height: 10)

            Text(title)
                .font(.callout)
                .foregroundStyle(CleanMacTheme.secondaryText)
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
                    asset: .diskOverview,
                    tint: tint
                )
                .frame(minHeight: 120)
            } else {
                ForEach(urls, id: \.self) { url in
                    HStack(spacing: 10) {
                        Image(systemName: "folder")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(tint)
                            .frame(width: 18)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(url.lastPathComponent.isEmpty ? url.path : url.lastPathComponent)
                                .lineLimit(1)
                            Text(url.path)
                                .font(.caption)
                                .foregroundStyle(CleanMacTheme.secondaryText)
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
                            .overlay(CleanMacTheme.ink.opacity(0.12))
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
    @State private var activationDate: Date?

    var body: some View {
        Group {
            if isAnimating {
                TimelineView(.animation) { timeline in
                    let progress = animationProgress(at: timeline.date)
                    iconContent(progress: progress)
                }
            } else {
                iconContent(progress: 0)
            }
        }
        .onAppear(perform: updateActivationDate)
        .onChange(of: isActive) { _, _ in updateActivationDate() }
        .onChange(of: reduceMotion) { _, _ in updateActivationDate() }
    }

    private var isAnimating: Bool {
        isActive && !reduceMotion
    }

    private func iconContent(progress: CGFloat) -> some View {
        Image(systemName: symbolName)
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(tint.opacity(isActive ? 0.24 : 0.16), in: CleanMacTheme.panelShape)
            .overlay {
                CleanMacTheme.panelShape
                    .strokeBorder(CleanMacTheme.ink, lineWidth: 2)
            }
            .scaleEffect(1.0 + (progress * 0.06))
    }

    private func updateActivationDate() {
        activationDate = isActive && !reduceMotion ? Date() : nil
    }

    private func animationProgress(at date: Date) -> CGFloat {
        guard let activationDate else {
            return 0
        }

        let elapsed = date.timeIntervalSince(activationDate)
        return oscillatingProgress(elapsed: elapsed, period: 0.9)
    }
}

struct CleanMacFeatureImage: View {
    var asset: CleanMacIllustrationAsset
    var tint: Color
    var isActive = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var activationDate: Date?

    var body: some View {
        Group {
            if isAnimating {
                TimelineView(.animation) { timeline in
                    let progress = animationProgress(at: timeline.date)
                    featureContent(progress: progress)
                }
            } else {
                featureContent(progress: 0)
            }
        }
        .onAppear(perform: updateActivationDate)
        .onChange(of: isActive) { _, _ in updateActivationDate() }
        .onChange(of: reduceMotion) { _, _ in updateActivationDate() }
    }

    private var isAnimating: Bool {
        isActive && !reduceMotion
    }

    @ViewBuilder
    private func featureContent(progress: CGFloat) -> some View {
        Group {
            if let image = CleanMacIllustrationImageCache.shared.image(for: asset) {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Color.clear
            }
        }
        .offset(y: -5 * progress)
        .scaleEffect(1.0 + (0.04 * progress))
    }

    private func updateActivationDate() {
        activationDate = isActive && !reduceMotion ? Date() : nil
    }

    private func animationProgress(at date: Date) -> CGFloat {
        guard let activationDate else {
            return 0
        }

        let elapsed = date.timeIntervalSince(activationDate)
        return oscillatingProgress(elapsed: elapsed, period: 3.0)
    }
}

@MainActor
private final class CleanMacIllustrationImageCache {
    static let shared = CleanMacIllustrationImageCache()

    private var images: [CleanMacIllustrationAsset: NSImage] = [:]
    private var missingAssets: Set<CleanMacIllustrationAsset> = []

    func image(for asset: CleanMacIllustrationAsset) -> NSImage? {
        if let image = images[asset] {
            return image
        }

        guard !missingAssets.contains(asset),
              let url = Bundle.module.url(forResource: asset.rawValue, withExtension: "png"),
              let image = NSImage(contentsOf: url)
        else {
            missingAssets.insert(asset)
            assertionFailure("Missing CleanMac illustration asset: \(asset.rawValue).png")
            return nil
        }

        images[asset] = image
        return image
    }
}

private func oscillatingProgress(elapsed: TimeInterval, period: TimeInterval) -> CGFloat {
    guard period > 0 else { return 0 }

    let phase = (elapsed / period) * 2 * Double.pi
    return CGFloat((1 - cos(phase)) / 2)
}

struct CleanMacProgressBeam: View {
    var tint: Color

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sweep = false

    var body: some View {
        GeometryReader { proxy in
            let shape = RoundedRectangle(cornerRadius: 4, style: .continuous)

            ZStack(alignment: .leading) {
                shape
                    .fill(tint.opacity(0.20))

                if reduceMotion {
                    shape
                        .fill(tint.opacity(0.44))
                } else {
                    LinearGradient(
                        colors: [.clear, tint.opacity(0.86), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: max(54, proxy.size.width * 0.36))
                    .offset(x: sweep ? proxy.size.width : -max(54, proxy.size.width * 0.36))
                }
            }
            .overlay {
                shape.strokeBorder(CleanMacTheme.ink, lineWidth: 1.5)
            }
            .clipped()
            .onAppear {
                sweep = !reduceMotion
            }
            .onChange(of: reduceMotion) { _, newValue in
                sweep = !newValue
            }
            .animation(CleanMacMotion.allowed(reduceMotion, CleanMacMotion.beam), value: sweep)
        }
    }
}

struct CleanMacRaisedButtonStyle: ButtonStyle {
    var tint: Color = CleanMacTheme.accent
    var prominent = false

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.callout.weight(.semibold))
            .lineLimit(1)
            .foregroundStyle(prominent ? CleanMacTheme.ink : tint)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background {
                CleanMacTheme.panelShape
                    .fill((prominent ? tint : CleanMacTheme.paper).opacity(isEnabled ? 1 : 0.55))
                    .shadow(
                        color: CleanMacTheme.shadow.opacity(isEnabled ? 1 : 0.45),
                        radius: 0,
                        x: 0,
                        y: configuration.isPressed ? 1 : 4
                    )
            }
            .overlay {
                CleanMacTheme.panelShape
                    .strokeBorder(CleanMacTheme.ink.opacity(isEnabled ? 1 : 0.38), lineWidth: 2)
            }
            .offset(y: configuration.isPressed ? 2 : 0)
            .opacity(isEnabled ? 1 : 0.58)
            .animation(CleanMacMotion.allowed(reduceMotion, CleanMacMotion.quick), value: configuration.isPressed)
    }
}
