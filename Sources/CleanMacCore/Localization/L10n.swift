import Foundation

public enum L10n {
    public enum Key: CaseIterable, Sendable {
        case add
        case aiReview
        case appLanguage
        case appTagline
        case applications
        case appUninstaller
        case askAI
        case candidates
        case category
        case cancel
        case cleaner
        case clear
        case clearSelection
        case aiTool
        case duplicateGroup
        case duplicates
        case edit
        case english
        case folders
        case followSystem
        case french
        case hiddenFiles
        case hindi
        case include
        case japanese
        case largeFile
        case manage
        case minimumSize
        case model
        case defaultModel
        case aiSummary
        case safeToDelete
        case riskyItems
        case needsUserReview
        case moveToTrash
        case moveSelectedItemsToTrash
        case moving
        case name
        case noCandidates
        case noApplicationsFound
        case noItemSelected
        case noReview
        case potential
        case permissions
        case protection
        case question
        case quitCleanMac
        case remove
        case results
        case reviewing
        case risk
        case rules
        case scan
        case scanApplications
        case scanOptions
        case scanning
        case selectAll
        case selectAllCandidates
        case selectDuplicateCopies
        case selectUninstallItems
        case selected
        case settings
        case size
        case spanish
        case status
        case openSettings
        case free
        case used
        case arabic
        case bengali
        case chinese
        case chineseTraditional
        case portuguese
        case copy
        case cut
        case paste
        case redo
        case russian
        case overviewPerformanceTitle
        case overviewPerformanceDetail
        case overviewJunkFilesTitle
        case overviewJunkFilesDetail
        case overviewUserFilesTitle
        case overviewUserFilesDetail
        case sidebarDiskOverviewTitle
        case sidebarDiskOverviewSubtitle
        case sidebarSpeedUpTitle
        case sidebarSpeedUpSubtitle
        case sidebarCleanUpTitle
        case sidebarCleanUpSubtitle
        case sidebarManageSpaceTitle
        case sidebarManageSpaceSubtitle
        case sidebarDuplicatesTitle
        case sidebarDuplicatesSubtitle
        case sidebarUninstallerTitle
        case sidebarUninstallerSubtitle
        case sidebarAnalyzeSpaceTitle
        case sidebarAnalyzeSpaceSubtitle
        case sidebarAIReviewTitle
        case sidebarAIReviewSubtitle
        case sidebarSettingsTitle
        case sidebarSettingsSubtitle
        case sidebarGroupOverview
        case sidebarGroupProTools
        case sidebarGroupAILocal
        case sidebarGroupSystem
        case undo
        case unknown

        fileprivate var resourceKey: String {
            String(describing: self)
        }
    }

    public static func text(_ key: Key, language: ResolvedLanguage) -> String {
        localized(key.resourceKey, language: language)
    }

    public static func languagePreferenceName(_ preference: AppLanguage, language: ResolvedLanguage) -> String {
        switch preference {
        case .system:
            return text(.followSystem, language: language)
        case .english:
            return text(.english, language: language)
        case .chinese:
            return text(.chinese, language: language)
        case .chineseTraditional:
            return text(.chineseTraditional, language: language)
        case .japanese:
            return text(.japanese, language: language)
        case .spanish:
            return text(.spanish, language: language)
        case .french:
            return text(.french, language: language)
        case .arabic:
            return text(.arabic, language: language)
        case .hindi:
            return text(.hindi, language: language)
        case .portuguese:
            return text(.portuguese, language: language)
        case .russian:
            return text(.russian, language: language)
        case .bengali:
            return text(.bengali, language: language)
        }
    }

    public static func categoryName(_ category: CandidateCategory, language: ResolvedLanguage) -> String {
        localized("category.\(category.rawValue)", language: language)
    }

    public static func riskName(_ risk: DeletionRisk, language: ResolvedLanguage) -> String {
        localized("risk.\(risk.rawValue)", language: language)
    }

    public static func protectionName(_ protection: DeletionProtection, language: ResolvedLanguage) -> String {
        localized("protection.\(protection.rawValue)", language: language)
    }

    public static func permissionStatusName(_ status: SystemPermissionStatus, language: ResolvedLanguage) -> String {
        localized("permissionStatus.\(status.rawValue)", language: language)
    }

    public static func permissionTitle(_ guide: SystemPermissionGuide, language: ResolvedLanguage) -> String {
        switch guide.kind {
        case .fullDiskAccess:
            return localized("permission.fullDiskAccess.title", language: language)
        }
    }

    public static func permissionExplanation(_ guide: SystemPermissionGuide, language: ResolvedLanguage) -> String {
        switch guide.kind {
        case .fullDiskAccess:
            return localized("permission.fullDiskAccess.explanation", language: language)
        }
    }

    public static func permissionInstructions(_ guide: SystemPermissionGuide, language: ResolvedLanguage) -> [String] {
        switch guide.kind {
        case .fullDiskAccess:
            return [
                localized("permission.fullDiskAccess.instruction.1", language: language),
                localized("permission.fullDiskAccess.instruction.2", language: language),
                localized("permission.fullDiskAccess.instruction.3", language: language)
            ]
        }
    }

    public static func protectedItemCount(_ count: Int, language: ResolvedLanguage) -> String {
        format("protectedItemCount", language: language, count)
    }

    public static func moveToTrashSummary(
        selectedCount: Int,
        protectedCount: Int,
        totalBytes: Int64,
        language: ResolvedLanguage
    ) -> String {
        let size = ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
        if protectedCount == 0 {
            return format("moveToTrashSummary.unprotected", language: language, selectedCount, size)
        }
        return format("moveToTrashSummary.protected", language: language, selectedCount, size, protectedCount)
    }

    public static func scanReason(_ reason: String, language: ResolvedLanguage) -> String {
        switch reason {
        case "Cache directory item":
            return localized("scanReason.cacheDirectoryItem", language: language)
        case "Log file or Logs directory item":
            return localized("scanReason.logFileOrLogsDirectoryItem", language: language)
        case "Downloads folder item":
            return localized("scanReason.downloadsFolderItem", language: language)
        case "Already in Trash":
            return localized("scanReason.alreadyInTrash", language: language)
        case "Temporary file location or extension":
            return localized("scanReason.temporaryFileLocationOrExtension", language: language)
        case "Developer cache or Xcode-derived data":
            return localized("scanReason.developerCacheOrXcodeDerivedData", language: language)
        case "Large file above configured threshold":
            return localized("scanReason.largeFileAboveConfiguredThreshold", language: language)
        case "No cleanup-specific pattern matched":
            return localized("scanReason.noCleanupSpecificPatternMatched", language: language)
        case let reason where reason.hasPrefix("Application bundle for "):
            let bundleIdentifier = String(reason.dropFirst("Application bundle for ".count))
            return format("scanReason.applicationBundle", language: language, bundleIdentifier)
        case let reason where reason.hasPrefix("App uninstall support item for "):
            let bundleIdentifier = String(reason.dropFirst("App uninstall support item for ".count))
            return format("scanReason.appUninstallSupportItem", language: language, bundleIdentifier)
        default:
            return reason
        }
    }

    public static func folderCount(_ count: Int, language: ResolvedLanguage) -> String {
        format("folderCount", language: language, count)
    }

    public static func candidateCount(_ count: Int, language: ResolvedLanguage) -> String {
        format("candidateCount", language: language, count)
    }

    public static func duplicateGroupCount(_ count: Int, language: ResolvedLanguage) -> String {
        format("duplicateGroupCount", language: language, count)
    }

    public static func uninstallPlanCount(_ count: Int, language: ResolvedLanguage) -> String {
        format("uninstallPlanCount", language: language, count)
    }

    public static func uninstallReclaimableBytes(_ bytes: Int64, language: ResolvedLanguage) -> String {
        let size = ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
        return format("uninstallReclaimableBytes", language: language, size)
    }

    public static func duplicateReclaimableBytes(_ bytes: Int64, language: ResolvedLanguage) -> String {
        let size = ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
        return format("duplicateReclaimableBytes", language: language, size)
    }

    public static func duplicateGroupDetail(_ group: DuplicateFileGroup, language: ResolvedLanguage) -> String {
        let reclaimable = ByteCountFormatter.string(fromByteCount: group.movableReclaimableBytes, countStyle: .file)
        return format("duplicateGroupDetail", language: language, group.candidates.count, reclaimable)
    }

    public static func appUninstallPlanDetail(_ plan: AppUninstallPlan, language: ResolvedLanguage) -> String {
        let reclaimable = ByteCountFormatter.string(fromByteCount: plan.movableReclaimableBytes, countStyle: .file)
        return format("appUninstallPlanDetail", language: language, plan.appName, plan.allCandidates.count, reclaimable)
    }

    public static func selectedCount(_ count: Int, language: ResolvedLanguage) -> String {
        format("selectedCount", language: language, count)
    }

    public static func selectedHeadline(_ count: Int, language: ResolvedLanguage) -> String {
        format("selectedHeadline", language: language, count)
    }

    public static func candidatesHeadline(_ count: Int, language: ResolvedLanguage) -> String {
        format("candidatesHeadline", language: language, count)
    }

    public static func storageFreeOfTotal(
        availableBytes: Int64,
        totalBytes: Int64,
        language: ResolvedLanguage
    ) -> String {
        let available = ByteCountFormatter.string(fromByteCount: availableBytes, countStyle: .file)
        let total = ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
        return format("storage.freeOfTotal", language: language, available, total)
    }

    public static func windowTitle(_ sectionTitle: String, language: ResolvedLanguage) -> String {
        format("windowTitle", language: language, sectionTitle)
    }

    public static func status(_ status: CleaningStatus, language: ResolvedLanguage) -> String {
        switch status {
        case .ready:
            return localized("status.ready", language: language)
        case .scanning:
            return localized("status.scanning", language: language)
        case .candidatesFound(let count):
            return format("status.candidatesFound", language: language, count)
        case .scanFailed:
            return localized("status.scanFailed", language: language)
        case .movingToTrash:
            return localized("status.movingToTrash", language: language)
        case .movedToTrash(let count):
            return format("status.movedToTrash", language: language, count)
        case .cleanupFailed:
            return localized("status.cleanupFailed", language: language)
        case .askingAI:
            return localized("status.askingAI", language: language)
        case .aiReviewFinished:
            return localized("status.aiReviewFinished", language: language)
        case .aiReviewFailed:
            return localized("status.aiReviewFailed", language: language)
        }
    }

    public static func error(_ error: CleaningErrorMessage, language: ResolvedLanguage) -> String {
        switch error {
        case .addFolderToScan:
            return localized("error.addFolderToScan", language: language)
        case .itemsCouldNotBeMoved(let count):
            return format("error.itemsCouldNotBeMoved", language: language, count)
        case .itemsWereProtected(let count):
            return format("error.itemsWereProtected", language: language, count)
        case .selectItemForAIReview:
            return localized("error.selectItemForAIReview", language: language)
        case .noAIToolDetected:
            return localized("error.noAIToolDetected", language: language)
        case .system(let message):
            return message
        }
    }

    public static func defaultAIQuestion(language: ResolvedLanguage) -> String {
        localized("defaultAIQuestion", language: language)
    }

    public static func isDefaultAIQuestion(_ question: String) -> Bool {
        let trimmedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        return ResolvedLanguage.allCases.contains {
            defaultAIQuestion(language: $0) == trimmedQuestion
        }
    }

    private static func localized(_ key: String, language: ResolvedLanguage) -> String {
        localizedBundle(for: language).localizedString(forKey: key, value: key, table: "Localizable")
    }

    private static func format(_ key: String, language: ResolvedLanguage, _ arguments: CVarArg...) -> String {
        let template = localized(key, language: language)
        return String(format: template, locale: language.locale, arguments: arguments)
    }

    private static func localizedBundle(for language: ResolvedLanguage) -> Bundle {
        let candidateLprojNames = [language.lprojName, language.lprojName.lowercased()]
        for lprojName in candidateLprojNames {
            if let path = Bundle.module.path(forResource: lprojName, ofType: "lproj"),
               let bundle = Bundle(path: path) {
                return bundle
            }
        }

        return Bundle.module
    }
}
