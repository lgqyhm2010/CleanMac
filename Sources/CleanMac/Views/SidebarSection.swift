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
        switch self {
        case .diskOverview: "Disk Overview"
        case .speedUp: "Speed up Mac"
        case .cleanUp: "Clean up Mac"
        case .manageSpace: "Manage space"
        case .duplicates: "Find duplicates"
        case .uninstaller: "Uninstall apps"
        case .analyzeSpace: "Analyze space"
        case .aiReview: "AI Review"
        case .settings: "Settings"
        }
    }

    func title(language: ResolvedLanguage) -> String {
        if language == .chinese {
            switch self {
            case .diskOverview: return "磁盘概览"
            case .speedUp: return "加速 Mac"
            case .cleanUp: return "清理 Mac"
            case .manageSpace: return "管理空间"
            case .duplicates: return "查找重复文件"
            case .uninstaller: return L10n.text(.appUninstaller, language: language)
            case .analyzeSpace: return "空间分析"
            case .aiReview: return L10n.text(.aiReview, language: language)
            case .settings: return L10n.text(.settings, language: language)
            }
        }

        if language == .chineseTraditional {
            switch self {
            case .diskOverview: return "磁碟概覽"
            case .speedUp: return "加速 Mac"
            case .cleanUp: return "清理 Mac"
            case .manageSpace: return "管理空間"
            case .duplicates: return "尋找重複檔案"
            case .uninstaller: return L10n.text(.appUninstaller, language: language)
            case .analyzeSpace: return "空間分析"
            case .aiReview: return L10n.text(.aiReview, language: language)
            case .settings: return L10n.text(.settings, language: language)
            }
        }

        return title
    }

    func subtitle(language: ResolvedLanguage) -> String {
        if language == .chinese {
            switch self {
            case .diskOverview: return "Macintosh HD"
            case .speedUp: return "性能"
            case .cleanUp: return "垃圾文件"
            case .manageSpace: return "用户文件"
            case .duplicates: return "精确匹配"
            case .uninstaller: return "应用清理"
            case .analyzeSpace: return "空间地图"
            case .aiReview: return "本地代理"
            case .settings: return "语言与更多"
            }
        }

        if language == .chineseTraditional {
            switch self {
            case .diskOverview: return "Macintosh HD"
            case .speedUp: return "效能"
            case .cleanUp: return "垃圾檔案"
            case .manageSpace: return "使用者檔案"
            case .duplicates: return "精確符合"
            case .uninstaller: return "應用程式清理"
            case .analyzeSpace: return "空間地圖"
            case .aiReview: return "本機代理"
            case .settings: return "語言與更多"
            }
        }

        return switch self {
        case .diskOverview: "Macintosh HD"
        case .speedUp: "Performance"
        case .cleanUp: "Junk files"
        case .manageSpace: "User files"
        case .duplicates: "Exact matches"
        case .uninstaller: "App cleaner"
        case .analyzeSpace: "Space map"
        case .aiReview: "Local agent"
        case .settings: "Language and more"
        }
    }

    var symbolName: String {
        switch self {
        case .diskOverview: "internaldrive"
        case .speedUp: "speedometer"
        case .cleanUp: "trash"
        case .manageSpace: "folder"
        case .duplicates: "doc.on.doc"
        case .uninstaller: "app.badge"
        case .analyzeSpace: "chart.bar"
        case .aiReview: "sparkles"
        case .settings: "gearshape"
        }
    }

    var illustrationAsset: CleanMacIllustrationAsset {
        switch self {
        case .diskOverview: .diskOverview
        case .speedUp: .permissionShield
        case .cleanUp: .cleanupTrash
        case .manageSpace: .diskOverview
        case .duplicates: .duplicates
        case .uninstaller: .cleanupTrash
        case .analyzeSpace: .diskOverview
        case .aiReview: .aiReview
        case .settings: .permissionShield
        }
    }

    var groupTitle: String {
        switch self {
        case .diskOverview, .speedUp, .cleanUp, .manageSpace:
            "Overview"
        case .duplicates, .uninstaller, .analyzeSpace:
            "Pro tools"
        case .aiReview:
            "AI - Local"
        case .settings:
            "System"
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
