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
                protection: .blocked
            ))
        }

        if isApplicationData(lowerPath), category != .applicationSupport {
            matches.append(rule(
                id: "app-data",
                protection: .blocked
            ))
        }

        if isSourceCode(lowerPath: lowerPath, lowerExtension: lowerExtension, lowerComponents: lowerComponents) {
            matches.append(rule(
                id: "source-code",
                protection: .requiresReview
            ))
        }

        if isCloudStorage(lowerPath: lowerPath, lowerComponents: lowerComponents) {
            matches.append(rule(
                id: "cloud-storage",
                protection: .requiresReview
            ))
        }

        switch category {
        case .cache:
            matches.append(rule(
                id: "cache",
                protection: .allowed
            ))
        case .logs:
            matches.append(rule(
                id: "logs",
                protection: .allowed
            ))
        case .temporary:
            matches.append(rule(
                id: "temporary",
                protection: .allowed
            ))
        case .trash:
            matches.append(rule(
                id: "trash",
                protection: .allowed
            ))
        case .downloads:
            matches.append(rule(
                id: "downloads",
                protection: .requiresReview
            ))
        case .largeFile:
            matches.append(rule(
                id: "large-file",
                protection: .requiresReview
            ))
        case .application:
            matches.append(rule(
                id: "app-bundle",
                protection: .requiresReview
            ))
        case .applicationSupport:
            matches.append(rule(
                id: "app-uninstall-support",
                protection: .requiresReview
            ))
        case .developer:
            matches.append(rule(
                id: "developer-cache",
                protection: .requiresReview
            ))
        case .other:
            break
        }

        if category == .other, isDirectory {
            matches.append(rule(
                id: "unknown-directory",
                protection: .blocked
            ))
        } else if matches.isEmpty {
            matches.append(fallbackRule(for: risk))
        }

        return SafetyEvaluation(
            protection: strongestProtection(in: matches),
            ruleMatches: matches,
            userVisibleRules: matches.map { L10n.safetyRule($0, language: .english) }
        )
    }

    private func rule(
        id: String,
        protection: DeletionProtection
    ) -> SafetyRuleMatch {
        SafetyRuleMatch(ruleID: id, protection: protection)
    }

    private func fallbackRule(for risk: DeletionRisk) -> SafetyRuleMatch {
        switch risk {
        case .usuallySafe:
            return rule(
                id: "risk-usually-safe",
                protection: .allowed
            )
        case .reviewRecommended:
            return rule(
                id: "risk-review",
                protection: .requiresReview
            )
        case .beCareful:
            return rule(
                id: "risk-careful",
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
