import CleanMacCore
import SwiftUI

struct ScanView: View {
    @ObservedObject var store: CleaningStore
    var language: ResolvedLanguage
    var openResults: () -> Void = {}
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        CleanMacPage(accent: CleanMacTheme.accent) {
            DiskOverviewHeader(store: store, language: language)

            DiskUsageOverviewCard(store: store, language: language)

            OverviewFeatureGrid(
                store: store,
                language: language,
                openResults: openResults
            )

            PermissionGuideView(
                guide: .fullDiskAccess(),
                language: language,
                displayStyle: .compact
            )

            CleanMacPanel(tint: CleanMacTheme.accent) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        CleanMacSectionHeader(
                            title: L10n.text(.folders, language: language),
                            symbolName: "folder",
                            tint: CleanMacTheme.accent
                        )
                        Button {
                            store.addFolderWithOpenPanel()
                        } label: {
                            Label(L10n.text(.add, language: language), systemImage: "plus")
                        }
                    }

                    CleanMacURLList(
                        urls: store.roots,
                        tint: CleanMacTheme.accent,
                        remove: store.removeRoot,
                        language: language
                    )
                }
            }

            CleanMacPanel(tint: CleanMacTheme.accent) {
                VStack(alignment: .leading, spacing: 14) {
                    CleanMacSectionHeader(
                        title: L10n.text(.scanOptions, language: language),
                        symbolName: "slider.horizontal.3",
                        tint: CleanMacTheme.accent
                    )

                    Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 12) {
                        GridRow {
                            Text(L10n.text(.minimumSize, language: language))
                            Slider(value: $store.minimumSizeMegabytes, in: 0...200, step: 1)
                            Text("\(Int(store.minimumSizeMegabytes)) MB")
                                .foregroundStyle(CleanMacTheme.secondaryText)
                                .monospacedDigit()
                        }

                        GridRow {
                            Text(L10n.text(.largeFile, language: language))
                            Slider(value: $store.largeFileThresholdMegabytes, in: 50...5_000, step: 50)
                            Text("\(Int(store.largeFileThresholdMegabytes)) MB")
                                .foregroundStyle(CleanMacTheme.secondaryText)
                                .monospacedDigit()
                        }

                        GridRow {
                            Text(L10n.text(.hiddenFiles, language: language))
                            Toggle(L10n.text(.include, language: language), isOn: $store.includeHiddenFiles)
                            Text("")
                        }
                    }

                    HStack {
                        Button {
                            store.scan()
                        } label: {
                            Label(
                                store.isScanning ? L10n.text(.scanning, language: language) : L10n.text(.scan, language: language),
                                systemImage: "magnifyingglass"
                            )
                        }
                        .buttonStyle(CleanMacRaisedButtonStyle(tint: CleanMacTheme.accent, prominent: true))
                        .disabled(store.isScanning || store.roots.isEmpty)

                        if store.isScanning {
                            ProgressView()
                                .controlSize(.small)
                                .transition(.opacity)
                        }

                        Spacer()

                        StatusText(store: store, language: language)
                    }

                    if store.isScanning {
                        CleanMacProgressBeam(tint: CleanMacTheme.accent)
                            .frame(height: 10)
                            .transition(.opacity)
                    }
                }
                .animation(CleanMacMotion.allowed(reduceMotion, CleanMacMotion.quick), value: store.isScanning)
            }
        }
    }
}

private struct DiskOverviewHeader: View {
    @ObservedObject var store: CleaningStore
    var language: ResolvedLanguage

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            CleanMacFeatureImage(asset: .mascot, tint: CleanMacTheme.accent, isActive: store.isScanning)
                .frame(width: 46, height: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text("Macintosh HD")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(CleanMacTheme.ink)
                Text(subtitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CleanMacTheme.accent)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(primaryValue)
                    .font(.title2.weight(.bold))
                    .monospacedDigit()
                Text(store.lastReport == nil ? "used" : L10n.text(.potential, language: language).lowercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CleanMacTheme.secondaryText)
            }
        }
    }

    private var primaryValue: String {
        guard let report = store.lastReport else { return "428 GB" }
        return Formatters.bytes(report.totalBytes)
    }

    private var subtitle: String {
        if store.isScanning {
            return L10n.text(.scanning, language: language)
        }

        guard let report = store.lastReport else {
            return "72 GB free of 500 GB total"
        }

        return "\(L10n.candidateCount(report.candidates.count, language: language)) - \(Formatters.bytes(report.totalBytes))"
    }
}

private struct DiskUsageOverviewCard: View {
    @ObservedObject var store: CleaningStore
    var language: ResolvedLanguage

    private let segments: [DiskSegment] = [
        .init(label: "System", value: "30 GB", color: Color(red: 0.66, green: 0.72, blue: 0.85), weight: 6),
        .init(label: "Cache", value: "12 GB", color: CleanMacTheme.peach, weight: 2.4),
        .init(label: "Junk", value: "75 GB", color: CleanMacTheme.accent, weight: 15),
        .init(label: "Video", value: "120 GB", color: CleanMacTheme.purple, weight: 24),
        .init(label: "Docs", value: "20 GB", color: CleanMacTheme.pink, weight: 4),
        .init(label: "Archives", value: "38 GB", color: CleanMacTheme.mint, weight: 7.6),
        .init(label: "Duplicates", value: "50 GB", color: CleanMacTheme.amber, weight: 10),
        .init(label: "Pictures", value: "35 GB", color: Color(red: 0.96, green: 0.72, blue: 0.59), weight: 7)
    ]

    var body: some View {
        CleanMacPanel(tint: CleanMacTheme.accent) {
            VStack(alignment: .leading, spacing: 12) {
                GeometryReader { proxy in
                    HStack(spacing: 0) {
                        ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                            segment.color
                                .frame(width: max(8, proxy.size.width * segment.weight / 100))
                                .overlay(alignment: .leading) {
                                    Rectangle()
                                        .fill(CleanMacTheme.ink)
                                        .frame(width: 2)
                                        .opacity(segment.label == segments.first?.label ? 0 : 1)
                                }
                        }

                        ZStack {
                            Color(red: 0.93, green: 0.91, blue: 0.86)
                            Text(store.lastReport == nil ? "72 GB free" : "free")
                                .font(.caption.weight(.bold))
                                .foregroundStyle(CleanMacTheme.accent)
                        }
                    }
                    .clipShape(Capsule())
                    .overlay {
                        Capsule()
                            .strokeBorder(CleanMacTheme.ink, lineWidth: 2.5)
                    }
                    .shadow(color: CleanMacTheme.ink, radius: 0, x: 2, y: 2)
                }
                .frame(height: 26)

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 12)], alignment: .leading, spacing: 7) {
                    ForEach(segments) { segment in
                        HStack(spacing: 5) {
                            RoundedRectangle(cornerRadius: 3, style: .continuous)
                                .fill(segment.color)
                                .frame(width: 9, height: 9)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                                        .strokeBorder(CleanMacTheme.ink, lineWidth: 1.2)
                                }
                            Text(segment.label)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(CleanMacTheme.secondaryText)
                            Text(segment.value)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(CleanMacTheme.ink)
                        }
                    }
                }
            }
        }
    }
}

private struct DiskSegment: Identifiable {
    var id: String { label }
    var label: String
    var value: String
    var color: Color
    var weight: CGFloat
}

private struct OverviewFeatureGrid: View {
    @ObservedObject var store: CleaningStore
    var language: ResolvedLanguage
    var openResults: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            OverviewActionCard(
                title: "Performance",
                detail: "Temp files and scan options that affect cleanup.",
                value: Formatters.bytes(store.lastReport?.totalBytes ?? 20_000_000_000),
                asset: .permissionShield,
                tint: CleanMacTheme.peach,
                buttonTitle: store.isScanning ? L10n.text(.scanning, language: language) : L10n.text(.scan, language: language),
                buttonSymbol: "play.fill",
                isActive: store.isScanning,
                action: {
                    store.scan()
                }
            )

            OverviewActionCard(
                title: "Junk Files",
                detail: "Cache, temporary files and logs ready for review.",
                value: Formatters.bytes(store.lastReport?.totalBytes ?? 32_000_000_000),
                asset: .cleanupTrash,
                tint: CleanMacTheme.accent,
                buttonTitle: L10n.text(.results, language: language),
                buttonSymbol: "arrow.right",
                isActive: store.isScanning,
                action: {
                    store.scan()
                    openResults()
                }
            )

            OverviewActionCard(
                title: "User Files",
                detail: "Large files, duplicate groups and selected cleanup items.",
                value: Formatters.bytes(store.selectedSummary.totalBytes == 0 ? store.duplicateReclaimableBytes : store.selectedSummary.totalBytes),
                asset: .duplicates,
                tint: CleanMacTheme.purple,
                buttonTitle: "Manage",
                buttonSymbol: "folder",
                action: openResults
            )
        }
    }
}

private struct OverviewActionCard: View {
    var title: String
    var detail: String
    var value: String
    var asset: CleanMacIllustrationAsset
    var tint: Color
    var buttonTitle: String
    var buttonSymbol: String
    var isActive = false
    var action: () -> Void

    var body: some View {
        CleanMacPanel(tint: tint) {
            VStack(spacing: 8) {
                CleanMacFeatureImage(asset: asset, tint: tint, isActive: isActive)
                    .frame(width: 64, height: 64)

                Text(title)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(tint)
                    .lineLimit(1)

                Text(detail)
                    .font(.caption)
                    .foregroundStyle(CleanMacTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(minHeight: 34)

                Text(value)
                    .font(.title3.weight(.bold))
                    .monospacedDigit()

                Button(action: action) {
                    Label(buttonTitle, systemImage: buttonSymbol)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(CleanMacRaisedButtonStyle(tint: tint, prominent: true))
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct SummaryStrip: View {
    @ObservedObject var store: CleaningStore
    var language: ResolvedLanguage

    var body: some View {
        HStack(spacing: 12) {
            MetricTileView(
                title: L10n.text(.candidates, language: language),
                value: "\(store.candidates.count)",
                symbolName: "doc.on.doc",
                asset: .diskOverview,
                tint: CleanMacTheme.accent,
                isActive: store.isScanning
            )
            MetricTileView(
                title: L10n.text(.potential, language: language),
                value: Formatters.bytes(store.lastReport?.totalBytes ?? 0),
                symbolName: "internaldrive",
                asset: .cleanupTrash,
                tint: CleanMacTheme.mint
            )
            MetricTileView(
                title: L10n.text(.duplicates, language: language),
                value: Formatters.bytes(store.duplicateReclaimableBytes),
                symbolName: "doc.on.doc.fill",
                asset: .duplicates,
                tint: CleanMacTheme.amber
            )
            MetricTileView(
                title: L10n.text(.selected, language: language),
                value: Formatters.bytes(store.selectedSummary.totalBytes),
                symbolName: "checkmark.circle",
                asset: .permissionShield,
                tint: CleanMacTheme.amber
            )
        }
    }
}

private struct StatusText: View {
    @ObservedObject var store: CleaningStore
    var language: ResolvedLanguage

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            StatusBadge(
                text: L10n.status(store.status, language: language),
                symbolName: CleanMacTheme.statusSymbol(store.status),
                tint: CleanMacTheme.statusColor(store.status),
                isActive: store.isScanning
            )
            if let error = store.errorMessage {
                Text(L10n.error(error, language: language))
                    .font(.caption)
                    .foregroundStyle(CleanMacTheme.danger)
                    .lineLimit(2)
            }
        }
        .foregroundStyle(CleanMacTheme.secondaryText)
    }
}
