import Foundation

public struct SafetyRuleEngine: Sendable {
    public init() {}

    public func evaluate(
        url: URL,
        category: CandidateCategory,
        risk: DeletionRisk,
        reasons: [String],
        isDirectory: Bool = false
    ) -> SafetyEvaluation {
        let path = url.standardizedFileURL.path
        let lowerPath = path.lowercased()
        let lowerExtension = url.pathExtension.lowercased()
        let lowerComponents = url.pathComponents.map { $0.lowercased() }
        var matches: [SafetyRuleMatch] = []

        if isSystemRoot(path), category != .application {
            matches.append(rule(
                id: "system-root",
                name: "System root",
                explanation: "System and shared macOS locations are protected from cleanup.",
                protection: .blocked
            ))
        }

        if isApplicationData(lowerPath), category != .applicationSupport {
            matches.append(rule(
                id: "app-data",
                name: "Application data",
                explanation: "Application support, containers, mail, messages, keychains, and browser data may contain live personal or app data.",
                protection: .blocked
            ))
        }

        if isSourceCode(lowerPath: lowerPath, lowerExtension: lowerExtension, lowerComponents: lowerComponents) {
            matches.append(rule(
                id: "source-code",
                name: "Source code",
                explanation: "Source projects and code files require manual review before cleanup.",
                protection: .requiresReview
            ))
        }

        if isCloudStorage(lowerPath: lowerPath, lowerComponents: lowerComponents) {
            matches.append(rule(
                id: "cloud-storage",
                name: "Cloud storage",
                explanation: "Cloud-synced files and placeholders require review so cleanup does not remove synced or offline-only content.",
                protection: .requiresReview
            ))
        }

        switch category {
        case .cache:
            matches.append(rule(
                id: "cache",
                name: "Cache",
                explanation: "Cache files are usually rebuildable, but still move to Trash first.",
                protection: .allowed
            ))
        case .logs:
            matches.append(rule(
                id: "logs",
                name: "Logs",
                explanation: "Log files are usually safe cleanup candidates after review.",
                protection: .allowed
            ))
        case .temporary:
            matches.append(rule(
                id: "temporary",
                name: "Temporary",
                explanation: "Temporary files are usually safe cleanup candidates.",
                protection: .allowed
            ))
        case .trash:
            matches.append(rule(
                id: "trash",
                name: "Trash",
                explanation: "Items already in Trash can be reviewed as cleanup candidates.",
                protection: .allowed
            ))
        case .downloads:
            matches.append(rule(
                id: "downloads",
                name: "Downloads",
                explanation: "Downloads may include installers or personal files; review before moving.",
                protection: .requiresReview
            ))
        case .largeFile:
            matches.append(rule(
                id: "large-file",
                name: "Large file",
                explanation: "Large files can reclaim space but are not automatically safe.",
                protection: .requiresReview
            ))
        case .application:
            matches.append(rule(
                id: "app-bundle",
                name: "Application bundle",
                explanation: "Applications should be reviewed with their support files before moving to Trash.",
                protection: .requiresReview
            ))
        case .applicationSupport:
            matches.append(rule(
                id: "app-uninstall-support",
                name: "App uninstall support",
                explanation: "This support item was matched to an application uninstall plan.",
                protection: .requiresReview
            ))
        case .developer:
            matches.append(rule(
                id: "developer-cache",
                name: "Developer data",
                explanation: "Developer files can include rebuildable caches and important source data; review before moving.",
                protection: .requiresReview
            ))
        case .other:
            break
        }

        if category == .other, isDirectory {
            matches.append(rule(
                id: "unknown-directory",
                name: "Unknown directory",
                explanation: "Unmatched folders are protected because deleting a directory has a wider blast radius.",
                protection: .blocked
            ))
        } else if matches.isEmpty {
            matches.append(fallbackRule(for: risk))
        }

        return SafetyEvaluation(
            protection: strongestProtection(in: matches),
            ruleMatches: matches,
            userVisibleRules: matches.map { "\($0.name): \($0.explanation)" }
        )
    }

    private func rule(
        id: String,
        name: String,
        explanation: String,
        protection: DeletionProtection
    ) -> SafetyRuleMatch {
        SafetyRuleMatch(
            ruleID: id,
            name: name,
            explanation: explanation,
            protection: protection
        )
    }

    private func fallbackRule(for risk: DeletionRisk) -> SafetyRuleMatch {
        switch risk {
        case .usuallySafe:
            return rule(
                id: "risk-usually-safe",
                name: "Low risk",
                explanation: "The classifier marked this item as usually safe.",
                protection: .allowed
            )
        case .reviewRecommended:
            return rule(
                id: "risk-review",
                name: "Review recommended",
                explanation: "No specific cleanup rule matched; review before moving.",
                protection: .requiresReview
            )
        case .beCareful:
            return rule(
                id: "risk-careful",
                name: "Be careful",
                explanation: "The classifier marked this item as high risk.",
                protection: .blocked
            )
        }
    }

    private func strongestProtection(in matches: [SafetyRuleMatch]) -> DeletionProtection {
        if matches.contains(where: { $0.protection == .blocked }) {
            return .blocked
        }
        if matches.contains(where: { $0.protection == .requiresReview }) {
            return .requiresReview
        }
        return .allowed
    }

    private func isSystemRoot(_ path: String) -> Bool {
        let protectedPrefixes = [
            "/System",
            "/Library",
            "/bin",
            "/sbin",
            "/usr",
            "/private/etc",
            "/private/var/db"
        ]
        return protectedPrefixes.contains { prefix in
            path == prefix || path.hasPrefix(prefix + "/")
        }
    }

    private func isApplicationData(_ lowerPath: String) -> Bool {
        let protectedFragments = [
            "/library/application support/",
            "/library/containers/",
            "/library/group containers/",
            "/library/keychains/",
            "/library/mail/",
            "/library/messages/",
            "/library/safari/",
            "/library/accounts/",
            "/library/preferences/"
        ]
        return protectedFragments.contains { lowerPath.contains($0) }
    }

    private func isSourceCode(
        lowerPath: String,
        lowerExtension: String,
        lowerComponents: [String]
    ) -> Bool {
        let sourceExtensions: Set<String> = [
            "c", "cc", "cpp", "cs", "go", "h", "hpp", "java", "js", "jsx",
            "kt", "m", "mm", "php", "py", "rb", "rs", "scala", "sh", "swift",
            "ts", "tsx"
        ]
        if sourceExtensions.contains(lowerExtension) {
            return true
        }
        if lowerPath.contains("/.git/") || lowerComponents.contains(".git") {
            return true
        }
        return lowerComponents.contains("sources")
            || lowerComponents.contains("source")
            || lowerComponents.contains("src")
    }

    private func isCloudStorage(lowerPath: String, lowerComponents: [String]) -> Bool {
        if lowerPath.contains("/library/mobile documents/")
            || lowerPath.contains("/library/cloudstorage/")
        {
            return true
        }

        return lowerComponents.contains { component in
            component == "dropbox"
                || component.hasPrefix("onedrive")
                || component == "icloud drive"
                || component == "google drive"
                || component.hasPrefix("google drive ")
        }
    }
}
