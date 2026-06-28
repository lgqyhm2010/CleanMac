import Foundation

public enum L10n {
    public enum Key: CaseIterable, Sendable {
        case add
        case aiCLI
        case aiReview
        case appLanguage
        case arguments
        case askAI
        case candidates
        case category
        case cancel
        case cleaner
        case clear
        case clearSelection
        case command
        case english
        case executable
        case folders
        case followSystem
        case hiddenFiles
        case include
        case largeFile
        case minimumSize
        case moveToTrash
        case moveSelectedItemsToTrash
        case moving
        case name
        case noCandidates
        case noItemSelected
        case noReview
        case potential
        case question
        case quitCleanMac
        case remove
        case results
        case reviewing
        case risk
        case scan
        case scanOptions
        case scanning
        case selectAll
        case selectAllCandidates
        case selected
        case settings
        case size
        case chinese
        case unknown
    }

    public static func text(_ key: Key, language: ResolvedLanguage) -> String {
        switch language {
        case .english:
            return englishText(key)
        case .chinese:
            return chineseText(key)
        }
    }

    public static func languagePreferenceName(_ preference: AppLanguage, language: ResolvedLanguage) -> String {
        switch preference {
        case .system:
            return text(.followSystem, language: language)
        case .english:
            return text(.english, language: language)
        case .chinese:
            return text(.chinese, language: language)
        }
    }

    public static func categoryName(_ category: CandidateCategory, language: ResolvedLanguage) -> String {
        switch language {
        case .english:
            return category.displayName
        case .chinese:
            switch category {
            case .cache: return "缓存"
            case .logs: return "日志"
            case .downloads: return "下载"
            case .trash: return "废纸篓"
            case .temporary: return "临时文件"
            case .developer: return "开发者"
            case .largeFile: return "大文件"
            case .other: return "其他"
            }
        }
    }

    public static func riskName(_ risk: DeletionRisk, language: ResolvedLanguage) -> String {
        switch language {
        case .english:
            return risk.displayName
        case .chinese:
            switch risk {
            case .usuallySafe: return "通常安全"
            case .reviewRecommended: return "建议检查"
            case .beCareful: return "谨慎处理"
            }
        }
    }

    public static func scanReason(_ reason: String, language: ResolvedLanguage) -> String {
        guard language == .chinese else {
            return reason
        }

        switch reason {
        case "Cache directory item":
            return "缓存目录项目"
        case "Log file or Logs directory item":
            return "日志文件或日志目录项目"
        case "Downloads folder item":
            return "下载文件夹项目"
        case "Already in Trash":
            return "已在废纸篓中"
        case "Temporary file location or extension":
            return "临时文件位置或扩展名"
        case "Developer cache or Xcode-derived data":
            return "开发缓存或 Xcode 派生数据"
        case "Large file above configured threshold":
            return "超过设定阈值的大文件"
        case "No cleanup-specific pattern matched":
            return "未匹配到明确的清理模式"
        default:
            return reason
        }
    }

    public static func folderCount(_ count: Int, language: ResolvedLanguage) -> String {
        switch language {
        case .english:
            return "\(count) folders"
        case .chinese:
            return "\(count) 个文件夹"
        }
    }

    public static func candidateCount(_ count: Int, language: ResolvedLanguage) -> String {
        switch language {
        case .english:
            return "\(count) candidates"
        case .chinese:
            return "\(count) 个候选项"
        }
    }

    public static func selectedCount(_ count: Int, language: ResolvedLanguage) -> String {
        switch language {
        case .english:
            return "\(count) selected"
        case .chinese:
            return "\(count) 个已选择"
        }
    }

    public static func selectedHeadline(_ count: Int, language: ResolvedLanguage) -> String {
        switch language {
        case .english:
            return "\(count) Selected"
        case .chinese:
            return "已选择 \(count) 个"
        }
    }

    public static func candidatesHeadline(_ count: Int, language: ResolvedLanguage) -> String {
        switch language {
        case .english:
            return "\(count) Candidates"
        case .chinese:
            return "\(count) 个候选项"
        }
    }

    public static func status(_ status: CleaningStatus, language: ResolvedLanguage) -> String {
        switch status {
        case .ready:
            return language == .english ? "Ready" : "就绪"
        case .scanning:
            return language == .english ? "Scanning..." : "正在扫描..."
        case .candidatesFound(let count):
            return language == .english ? "\(count) candidates found" : "找到 \(count) 个候选项"
        case .scanFailed:
            return language == .english ? "Scan failed" : "扫描失败"
        case .movingToTrash:
            return language == .english ? "Moving to Trash..." : "正在移到废纸篓..."
        case .movedToTrash(let count):
            return language == .english ? "\(count) items moved to Trash" : "已将 \(count) 个项目移到废纸篓"
        case .cleanupFailed:
            return language == .english ? "Cleanup failed" : "清理失败"
        case .askingAI:
            return language == .english ? "Asking AI..." : "正在询问 AI..."
        case .aiReviewFinished:
            return language == .english ? "AI review finished" : "AI 审查完成"
        case .aiReviewFailed:
            return language == .english ? "AI review failed" : "AI 审查失败"
        }
    }

    public static func error(_ error: CleaningErrorMessage, language: ResolvedLanguage) -> String {
        switch error {
        case .addFolderToScan:
            return language == .english ? "Add at least one folder to scan." : "请至少添加一个要扫描的文件夹。"
        case .itemsCouldNotBeMoved(let count):
            return language == .english ? "\(count) items could not be moved." : "\(count) 个项目无法移动。"
        case .selectItemForAIReview:
            return language == .english ? "Select at least one item for AI review." : "请至少选择一个项目供 AI 审查。"
        case .setAIExecutable:
            return language == .english ? "Set an AI CLI executable in Settings." : "请在设置中配置 AI CLI 可执行文件。"
        case .system(let message):
            return message
        }
    }

    public static func defaultAIQuestion(language: ResolvedLanguage) -> String {
        switch language {
        case .english:
            return "Please decide whether these files are suitable to move to Trash, and list anything I should manually confirm."
        case .chinese:
            return "请判断这些文件是否适合移到废纸篓，并列出需要我手动确认的项目。"
        }
    }

    public static func isDefaultAIQuestion(_ question: String) -> Bool {
        let trimmedQuestion = question.trimmingCharacters(in: .whitespacesAndNewlines)
        return ResolvedLanguage.allCases.contains {
            defaultAIQuestion(language: $0) == trimmedQuestion
        }
    }

    private static func englishText(_ key: Key) -> String {
        switch key {
        case .add: return "Add"
        case .aiCLI: return "AI CLI"
        case .aiReview: return "AI Review"
        case .appLanguage: return "Language"
        case .arguments: return "Arguments"
        case .askAI: return "Ask AI"
        case .candidates: return "Candidates"
        case .category: return "Category"
        case .cancel: return "Cancel"
        case .cleaner: return "Cleaner"
        case .clear: return "Clear"
        case .clearSelection: return "Clear Selection"
        case .command: return "Command"
        case .english: return "English"
        case .executable: return "Executable"
        case .folders: return "Folders"
        case .followSystem: return "Follow System"
        case .hiddenFiles: return "Hidden Files"
        case .include: return "Include"
        case .largeFile: return "Large File"
        case .minimumSize: return "Minimum Size"
        case .moveToTrash: return "Move to Trash"
        case .moveSelectedItemsToTrash: return "Move selected items to Trash?"
        case .moving: return "Moving"
        case .name: return "Name"
        case .noCandidates: return "No Candidates"
        case .noItemSelected: return "No item selected"
        case .noReview: return "No Review"
        case .potential: return "Potential"
        case .question: return "Question"
        case .quitCleanMac: return "Quit CleanMac"
        case .remove: return "Remove"
        case .results: return "Results"
        case .reviewing: return "Reviewing"
        case .risk: return "Risk"
        case .scan: return "Scan"
        case .scanOptions: return "Scan Options"
        case .scanning: return "Scanning"
        case .selectAll: return "Select All"
        case .selectAllCandidates: return "Select All Candidates"
        case .selected: return "Selected"
        case .settings: return "Settings"
        case .size: return "Size"
        case .chinese: return "Chinese"
        case .unknown: return "Unknown"
        }
    }

    private static func chineseText(_ key: Key) -> String {
        switch key {
        case .add: return "添加"
        case .aiCLI: return "AI CLI"
        case .aiReview: return "AI 审查"
        case .appLanguage: return "语言"
        case .arguments: return "参数"
        case .askAI: return "询问 AI"
        case .candidates: return "候选项"
        case .category: return "类别"
        case .cancel: return "取消"
        case .cleaner: return "清理器"
        case .clear: return "清除"
        case .clearSelection: return "清除选择"
        case .command: return "命令"
        case .english: return "English"
        case .executable: return "可执行文件"
        case .folders: return "文件夹"
        case .followSystem: return "跟随系统"
        case .hiddenFiles: return "隐藏文件"
        case .include: return "包含"
        case .largeFile: return "大文件"
        case .minimumSize: return "最小大小"
        case .moveToTrash: return "移到废纸篓"
        case .moveSelectedItemsToTrash: return "将选中项目移到废纸篓？"
        case .moving: return "正在移动"
        case .name: return "名称"
        case .noCandidates: return "没有候选项"
        case .noItemSelected: return "未选择项目"
        case .noReview: return "没有审查结果"
        case .potential: return "可清理"
        case .question: return "问题"
        case .quitCleanMac: return "退出 CleanMac"
        case .remove: return "移除"
        case .results: return "结果"
        case .reviewing: return "正在审查"
        case .risk: return "风险"
        case .scan: return "扫描"
        case .scanOptions: return "扫描选项"
        case .scanning: return "正在扫描"
        case .selectAll: return "全选"
        case .selectAllCandidates: return "全选候选项"
        case .selected: return "已选择"
        case .settings: return "设置"
        case .size: return "大小"
        case .chinese: return "中文"
        case .unknown: return "未知"
        }
    }
}
