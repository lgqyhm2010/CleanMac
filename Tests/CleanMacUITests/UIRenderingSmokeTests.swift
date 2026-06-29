import AppKit
import SwiftUI
import XCTest
@testable import CleanMac

@MainActor
final class UIRenderingSmokeTests: XCTestCase {
    func testEverySidebarPageRendersVisibleMainContent() throws {
        for section in SidebarSection.allCases {
            let store = CleaningStore(language: .english)
            let view = ContentView(store: store, initialSelection: section)
                .frame(width: 1_180, height: 760)

            let image = render(view)
            try saveSnapshotIfRequested(image, named: section.rawValue)
            let averageBrightness = try averageBrightness(
                of: image,
                in: CGRect(x: 260, y: 80, width: 840, height: 560)
            )

            XCTAssertGreaterThan(
                averageBrightness,
                0.08,
                "\(section.title) rendered as a near-black main content area"
            )

            let darkControlRatio = try darkControlPixelRatio(
                of: image,
                in: CGRect(x: 230, y: 30, width: 930, height: 700)
            )

            XCTAssertLessThan(
                darkControlRatio,
                0.05,
                "\(section.title) rendered unusually large dark controls"
            )
        }
    }

    private func render<V: View>(_ view: V) -> NSImage {
        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = NSRect(x: 0, y: 0, width: 1_180, height: 760)
        hostingView.layoutSubtreeIfNeeded()

        let representation = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds)!
        hostingView.cacheDisplay(in: hostingView.bounds, to: representation)

        let image = NSImage(size: hostingView.bounds.size)
        image.addRepresentation(representation)
        return image
    }

    private func saveSnapshotIfRequested(_ image: NSImage, named name: String) throws {
        guard let snapshotDirectory = ProcessInfo.processInfo.environment["CLEANMAC_UI_SNAPSHOT_DIR"] else { return }
        let directoryURL = URL(filePath: snapshotDirectory, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        guard
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData),
            let pngData = bitmap.representation(using: .png, properties: [:])
        else {
            XCTFail("Unable to encode snapshot for \(name)")
            return
        }

        try pngData.write(to: directoryURL.appending(path: "\(name).png"))
    }

    private func averageBrightness(of image: NSImage, in rect: CGRect) throws -> Double {
        guard
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData)
        else {
            XCTFail("Unable to read rendered image data")
            return 0
        }

        let minX = max(0, Int(rect.minX))
        let maxX = min(bitmap.pixelsWide, Int(rect.maxX))
        let minY = max(0, Int(rect.minY))
        let maxY = min(bitmap.pixelsHigh, Int(rect.maxY))
        var total = 0.0
        var count = 0

        for y in stride(from: minY, to: maxY, by: 20) {
            for x in stride(from: minX, to: maxX, by: 20) {
                guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.sRGB) else { continue }
                total += (Double(color.redComponent) + Double(color.greenComponent) + Double(color.blueComponent)) / 3.0
                count += 1
            }
        }

        guard count > 0 else {
            XCTFail("No pixels sampled from rendered image")
            return 0
        }
        return total / Double(count)
    }

    private func darkControlPixelRatio(of image: NSImage, in rect: CGRect) throws -> Double {
        guard
            let tiffData = image.tiffRepresentation,
            let bitmap = NSBitmapImageRep(data: tiffData)
        else {
            XCTFail("Unable to read rendered image data")
            return 1
        }

        let minX = max(0, Int(rect.minX))
        let maxX = min(bitmap.pixelsWide, Int(rect.maxX))
        let minY = max(0, Int(rect.minY))
        let maxY = min(bitmap.pixelsHigh, Int(rect.maxY))
        var darkPixelCount = 0
        var sampleCount = 0

        for y in stride(from: minY, to: maxY, by: 4) {
            for x in stride(from: minX, to: maxX, by: 4) {
                guard let color = bitmap.colorAt(x: x, y: y)?.usingColorSpace(.sRGB) else { continue }
                let brightness = (Double(color.redComponent) + Double(color.greenComponent) + Double(color.blueComponent)) / 3.0
                if brightness < 0.12 {
                    darkPixelCount += 1
                }
                sampleCount += 1
            }
        }

        guard sampleCount > 0 else {
            XCTFail("No pixels sampled from rendered image")
            return 1
        }
        return Double(darkPixelCount) / Double(sampleCount)
    }
}
