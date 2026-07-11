import Foundation
import XCTest

final class ReleaseEngineeringTests: XCTestCase {
    func testPullRequestPackagingIsReadOnlyAndSecretFree() throws {
        let workflow = try sourceFile(".github/workflows/release-dmg.yml")
        let previewJob = try XCTUnwrap(
            workflow.slice(from: "  verify-preview:\n", to: "  release:\n"),
            "Release workflow must keep preview verification separate from publishing"
        )

        XCTAssertTrue(workflow.contains("permissions:\n  contents: read"))
        XCTAssertTrue(previewJob.contains("permissions:\n      contents: read"))
        XCTAssertTrue(previewJob.contains("./script/build_dmg.sh --unsigned"))
        XCTAssertFalse(previewJob.contains("secrets."))
        XCTAssertFalse(previewJob.contains("contents: write"))
    }

    func testPublishingRunsOnlyForTagsAndFailsClosed() throws {
        let workflow = try sourceFile(".github/workflows/release-dmg.yml")
        let releaseJob = try XCTUnwrap(workflow.tail(from: "  release:\n"))
        let script = try sourceFile("script/build_dmg.sh")

        XCTAssertTrue(releaseJob.contains("if: startsWith(github.ref, 'refs/tags/v')"))
        XCTAssertTrue(releaseJob.contains("permissions:\n      contents: write"))
        XCTAssertTrue(releaseJob.contains("MACOS_CERT_P12_BASE64"))
        XCTAssertTrue(releaseJob.contains("APPLE_APP_PASSWORD"))

        XCTAssertTrue(script.contains("--unsigned"), "Unsigned preview packaging must be explicit")
        XCTAssertTrue(script.contains("Developer ID Application"))
        XCTAssertTrue(script.contains("xcrun notarytool submit"))
        XCTAssertTrue(script.contains(#"NOTARY_STATUS"#))
        XCTAssertTrue(script.contains(#"= "Accepted""#))
        XCTAssertTrue(script.contains("xcrun stapler validate"))
        XCTAssertTrue(script.contains("spctl --assess"))
        XCTAssertFalse(script.contains("SKIP_NOTARIZE"))
        XCTAssertFalse(script.contains("|| warn"))
        XCTAssertFalse(script.contains("DEGRADES GRACEFULLY"))
    }

    func testEveryGitHubActionIsPinnedToACommit() throws {
        let workflowDirectory = packageRoot().appending(path: ".github/workflows")
        let workflowURLs = try FileManager.default.contentsOfDirectory(
            at: workflowDirectory,
            includingPropertiesForKeys: nil
        ).filter { ["yml", "yaml"].contains($0.pathExtension) }
        let usesPattern = try NSRegularExpression(pattern: #"(?m)^\s*uses:\s*[^@\s]+@([^\s#]+)"#)
        let shaPattern = try NSRegularExpression(pattern: #"^[0-9a-f]{40}$"#)

        for url in workflowURLs {
            let source = try String(contentsOf: url, encoding: .utf8)
            let range = NSRange(source.startIndex..., in: source)
            for match in usesPattern.matches(in: source, range: range) {
                let ref = (source as NSString).substring(with: match.range(at: 1))
                XCTAssertEqual(
                    shaPattern.numberOfMatches(in: ref, range: NSRange(ref.startIndex..., in: ref)),
                    1,
                    "\(url.lastPathComponent) uses an unpinned action ref: \(ref)"
                )
            }
        }
    }

    func testReleaseBundleIsUniversalVersionedAndExcludesSourceArtwork() throws {
        let bundleScript = try sourceFile("script/build_and_run.sh")
        let package = try sourceFile("Package.swift")
        let appTarget = try XCTUnwrap(
            package.slice(from: ".executableTarget(\n", to: "        .target(\n")
        )

        XCTAssertTrue(bundleScript.contains("arm64-apple-macosx14.0"))
        XCTAssertTrue(bundleScript.contains("x86_64-apple-macosx14.0"))
        XCTAssertTrue(bundleScript.contains("lipo -create"))
        XCTAssertTrue(bundleScript.contains("CFBundleShortVersionString"))
        XCTAssertTrue(bundleScript.contains("CFBundleVersion"))
        XCTAssertTrue(bundleScript.contains("verify_release.sh"))

        XCTAssertTrue(appTarget.contains(#".process("Resources/Images")"#))
        XCTAssertTrue(appTarget.contains(#""Resources/ImagesSource""#))
        XCTAssertFalse(appTarget.contains(#".process("Resources")"#))
    }

    func testReleaseVerificationChecksTheBuiltArtifact() throws {
        let verifier = try sourceFile("script/verify_release.sh")

        XCTAssertTrue(verifier.contains("CFBundleShortVersionString"))
        XCTAssertTrue(verifier.contains("CFBundleVersion"))
        XCTAssertTrue(verifier.contains("lipo -archs"))
        XCTAssertTrue(verifier.contains("arm64"))
        XCTAssertTrue(verifier.contains("x86_64"))
        XCTAssertTrue(verifier.contains("-key.png"))
    }

    func testDocumentationDoesNotRecommendQuarantineBypass() throws {
        let readmes = try FileManager.default.contentsOfDirectory(
            at: packageRoot(),
            includingPropertiesForKeys: nil
        ).filter { $0.lastPathComponent.hasPrefix("README") && $0.pathExtension == "md" }

        for readme in readmes {
            let source = try String(contentsOf: readme, encoding: .utf8)
            XCTAssertFalse(source.localizedCaseInsensitiveContains("xattr"), readme.lastPathComponent)
        }
    }

    func testReviewWorkflowDoesNotInstallFloatingPlugins() throws {
        let workflow = try sourceFile(".github/workflows/claude-code-review.yml")

        XCTAssertFalse(workflow.contains("plugin_marketplaces:"))
        XCTAssertFalse(workflow.contains("plugins:"))
    }

    func testReleaseScriptFailureHarness() throws {
        let process = Process()
        let output = Pipe()
        process.executableURL = URL(filePath: "/bin/bash")
        process.arguments = [packageRoot().appending(path: "Tests/ReleaseScriptTests.sh").path]
        process.currentDirectoryURL = packageRoot()
        process.standardOutput = output
        process.standardError = output

        try process.run()
        process.waitUntilExit()
        let data = output.fileHandleForReading.readDataToEndOfFile()
        let text = String(decoding: data, as: UTF8.self)

        XCTAssertEqual(process.terminationStatus, 0, text)
        XCTAssertTrue(text.contains("release fail-closed harness passed"), text)
    }

    private func packageRoot() -> URL {
        URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    private func sourceFile(_ relativePath: String) throws -> String {
        try String(contentsOf: packageRoot().appending(path: relativePath), encoding: .utf8)
    }
}

private extension String {
    func slice(from startMarker: String, to endMarker: String) -> String? {
        guard
            let start = range(of: startMarker)?.lowerBound,
            let end = range(of: endMarker, range: start..<endIndex)?.lowerBound
        else { return nil }
        return String(self[start..<end])
    }

    func tail(from marker: String) -> String? {
        guard let start = range(of: marker)?.lowerBound else { return nil }
        return String(self[start...])
    }
}
