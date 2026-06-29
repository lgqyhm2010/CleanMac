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
    static let titlebar = Color(hex: 0x2C2640)
    static let sidebar = Color(hex: 0x2C2640)
    static let sidebarBorder = Color(hex: 0x3A3458)
    static let sidebarText = Color(hex: 0x7070C0)
    static let sidebarPrimaryText = Color(hex: 0xE8E0FF)
    static let sidebarRowText = Color(hex: 0xC0C0E0)
    static let secondaryText = Color(hex: 0x706B82)

    static let accent = Color(hex: 0x5DAEE7)
    static let mint = Color(hex: 0x74C6A6)
    static let amber = Color(hex: 0xF6C94E)
    static let purple = Color(hex: 0xA685DF)
    static let pink = Color(hex: 0xEF96B5)
    static let peach = Color(hex: 0xF2A67F)
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
    case cleanupTrash = "feature-cleanup-trash"
    case duplicates = "feature-duplicates"
    case aiReview = "feature-ai-review"
    case permissionShield = "feature-permission-shield"

    var fallbackSymbolName: String {
        switch self {
        case .mascot: "desktopcomputer"
        case .diskOverview: "internaldrive"
        case .cleanupTrash: "trash"
        case .duplicates: "doc.on.doc"
        case .aiReview: "sparkles"
        case .permissionShield: "lock.shield"
        }
    }
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
            VStack(alignment: .leading, spacing: CleanMacTheme.sectionSpacing) {
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

                Circle()
                    .fill(accent.opacity(0.16))
                    .frame(width: min(proxy.size.width, 460), height: min(proxy.size.width, 460))
                    .blur(radius: 70)
                    .offset(x: proxy.size.width * 0.30, y: -proxy.size.height * 0.30)

                Circle()
                    .fill(CleanMacTheme.peach.opacity(0.11))
                    .frame(width: 360, height: 360)
                    .blur(radius: 80)
                    .offset(x: -proxy.size.width * 0.36, y: proxy.size.height * 0.30)

                CleanMacSparkle(position: CGPoint(x: proxy.size.width * 0.86, y: proxy.size.height * 0.18), delay: 0.1)
                CleanMacSparkle(position: CGPoint(x: proxy.size.width * 0.68, y: proxy.size.height * 0.72), delay: 0.8)
                CleanMacSparkle(position: CGPoint(x: proxy.size.width * 0.16, y: proxy.size.height * 0.30), delay: 1.3)
            }
            .ignoresSafeArea()
        }
    }
}

struct CleanMacAppTitleBar: View {
    var title: String

    var body: some View {
        ZStack {
            CleanMacTheme.titlebar

            HStack(spacing: 8) {
                Spacer()
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(hex: 0x9090B0))
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 78)
        }
        .frame(height: 30)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(CleanMacTheme.ink)
                .frame(height: 1.5)
        }
    }
}

private struct CleanMacSparkle: View {
    var position: CGPoint
    var delay: Double

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var visible = false

    var body: some View {
        Image(systemName: "sparkle")
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(CleanMacTheme.ink.opacity(0.18))
            .scaleEffect(visible ? 1.18 : 0.82)
            .opacity(visible ? 0.30 : 0.12)
            .position(position)
            .animation(CleanMacMotion.allowed(reduceMotion, .easeInOut(duration: 1.8).delay(delay).repeatForever(autoreverses: true)), value: visible)
            .onAppear {
                visible = !reduceMotion
            }
            .onChange(of: reduceMotion) { _, newValue in
                visible = !newValue
            }
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
            .background(CleanMacTheme.paper, in: CleanMacTheme.panelShape)
            .overlay {
                CleanMacTheme.panelShape
                    .strokeBorder(CleanMacTheme.ink, lineWidth: CleanMacTheme.outlineWidth)
            }
            .shadow(color: CleanMacTheme.shadow, radius: 0, x: 0, y: 5)
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
        .background(CleanMacTheme.paper, in: CleanMacTheme.panelShape)
        .overlay {
            CleanMacTheme.panelShape
                .strokeBorder(CleanMacTheme.ink, lineWidth: 2)
        }
        .shadow(color: CleanMacTheme.shadow, radius: 0, x: 0, y: 4)
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
    @State private var pulsing = false

    var body: some View {
        Image(systemName: symbolName)
            .symbolRenderingMode(.hierarchical)
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(tint.opacity(isActive ? 0.24 : 0.16), in: CleanMacTheme.panelShape)
            .overlay {
                CleanMacTheme.panelShape
                    .strokeBorder(CleanMacTheme.ink, lineWidth: 2)
            }
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

struct CleanMacFeatureImage: View {
    var asset: CleanMacIllustrationAsset
    var tint: Color
    var isActive = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var floating = false

    var body: some View {
        Group {
            if let image = image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                CleanMacPulseIcon(symbolName: asset.fallbackSymbolName, tint: tint, isActive: isActive)
            }
        }
        .offset(y: floating ? -5 : 0)
        .scaleEffect(floating ? 1.04 : 1.0)
        .animation(CleanMacMotion.allowed(reduceMotion, CleanMacMotion.float), value: floating)
        .onAppear(perform: updateFloat)
        .onChange(of: isActive) { _, _ in updateFloat() }
        .onChange(of: reduceMotion) { _, _ in updateFloat() }
    }

    private var image: NSImage? {
        guard let url = Bundle.module.url(forResource: asset.rawValue, withExtension: "png", subdirectory: "Images") else {
            return nil
        }
        return NSImage(contentsOf: url)
    }

    private func updateFloat() {
        floating = isActive && !reduceMotion
    }
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
            .background((prominent ? tint : CleanMacTheme.paper).opacity(isEnabled ? 1 : 0.55), in: CleanMacTheme.panelShape)
            .overlay {
                CleanMacTheme.panelShape
                    .strokeBorder(CleanMacTheme.ink.opacity(isEnabled ? 1 : 0.38), lineWidth: 2)
            }
            .shadow(color: CleanMacTheme.shadow.opacity(isEnabled ? 1 : 0.45), radius: 0, x: 0, y: configuration.isPressed ? 1 : 4)
            .offset(y: configuration.isPressed ? 2 : 0)
            .opacity(isEnabled ? 1 : 0.58)
            .animation(CleanMacMotion.allowed(reduceMotion, CleanMacMotion.quick), value: configuration.isPressed)
    }
}
