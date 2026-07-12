import CleanMacCore
import SwiftUI

extension Color {
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
