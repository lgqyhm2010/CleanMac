import CleanMacCore
import Foundation

enum SidebarSection: String, CaseIterable, Identifiable, Hashable {
    case diskOverview
    case speedUp
    case cleanUp
    case manageSpace
    case duplicates
    case uninstaller
    case analyzeSpace
    case aiReview
    case settings

    var id: String { rawValue }

    var title: String {
        title(language: .english)
    }

    func title(language: ResolvedLanguage) -> String {
        L10n.text(titleKey, language: language)
    }

    func subtitle(language: ResolvedLanguage) -> String {
        L10n.text(subtitleKey, language: language)
    }

    var illustrationAsset: CleanMacIllustrationAsset {
        switch self {
        case .diskOverview: .diskOverview
        case .speedUp: .speedUp
        case .cleanUp: .cleanupTrash
        case .manageSpace: .manageSpace
        case .duplicates: .duplicates
        case .uninstaller: .appUninstall
        case .analyzeSpace: .spaceAnalysis
        case .aiReview: .aiReview
        case .settings: .settings
        }
    }

    func groupTitle(language: ResolvedLanguage) -> String {
        L10n.text(groupTitleKey, language: language)
    }

    private var titleKey: L10n.Key {
        switch self {
        case .diskOverview: .sidebarDiskOverviewTitle
        case .speedUp: .sidebarSpeedUpTitle
        case .cleanUp: .sidebarCleanUpTitle
        case .manageSpace: .sidebarManageSpaceTitle
        case .duplicates: .sidebarDuplicatesTitle
        case .uninstaller: .sidebarUninstallerTitle
        case .analyzeSpace: .sidebarAnalyzeSpaceTitle
        case .aiReview: .sidebarAIReviewTitle
        case .settings: .sidebarSettingsTitle
        }
    }

    private var subtitleKey: L10n.Key {
        switch self {
        case .diskOverview: .sidebarDiskOverviewSubtitle
        case .speedUp: .sidebarSpeedUpSubtitle
        case .cleanUp: .sidebarCleanUpSubtitle
        case .manageSpace: .sidebarManageSpaceSubtitle
        case .duplicates: .sidebarDuplicatesSubtitle
        case .uninstaller: .sidebarUninstallerSubtitle
        case .analyzeSpace: .sidebarAnalyzeSpaceSubtitle
        case .aiReview: .sidebarAIReviewSubtitle
        case .settings: .sidebarSettingsSubtitle
        }
    }

    private var groupTitleKey: L10n.Key {
        switch self {
        case .diskOverview, .speedUp, .cleanUp, .manageSpace: .sidebarGroupOverview
        case .duplicates, .uninstaller, .analyzeSpace: .sidebarGroupProTools
        case .aiReview: .sidebarGroupAILocal
        case .settings: .sidebarGroupSystem
        }
    }

    var contentTarget: SidebarContentTarget {
        switch self {
        case .diskOverview, .speedUp:
            .scan
        case .cleanUp, .manageSpace, .duplicates, .analyzeSpace:
            .results
        case .uninstaller:
            .uninstaller
        case .aiReview:
            .aiReview
        case .settings:
            .settings
        }
    }
}

enum SidebarContentTarget {
    case scan
    case results
    case uninstaller
    case aiReview
    case settings
}
