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
                Text(volumeName)
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
                Text(store.lastReport == nil ? L10n.text(.used, language: language).lowercased() : L10n.text(.potential, language: language).lowercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CleanMacTheme.secondaryText)
            }
        }
    }

    private var volumeName: String {
        store.volumeSnapshot?.name ?? L10n.text(.unknown, language: language)
    }

    private var primaryValue: String {
        if let report = store.lastReport {
            return Formatters.bytes(report.totalBytes)
        }
        guard let snapshot = store.volumeSnapshot else { return Formatters.bytes(0) }
        return Formatters.bytes(snapshot.usedCapacityBytes)
    }

    private var subtitle: String {
        if store.isScanning {
            return L10n.text(.scanning, language: language)
        }

        if let report = store.lastReport {
            return "\(L10n.candidateCount(report.candidates.count, language: language)) - \(Formatters.bytes(report.totalBytes))"
        }

        guard let snapshot = store.volumeSnapshot else {
            return L10n.text(.unknown, language: language)
        }

        return L10n.storageFreeOfTotal(
            availableBytes: snapshot.availableCapacityBytes,
            totalBytes: snapshot.totalCapacityBytes,
            language: language
        )
    }
}

private struct DiskUsageOverviewCard: View {
    @ObservedObject var store: CleaningStore
    var language: ResolvedLanguage

    private var segments: [DiskSegment] {
        if let report = store.lastReport, !report.candidates.isEmpty {
            return candidateSegments(for: report)
        }

        guard let snapshot = store.volumeSnapshot else { return [] }
        return volumeSegments(for: snapshot)
    }

    var body: some View {
        CleanMacPanel(tint: CleanMacTheme.accent) {
            VStack(alignment: .leading, spacing: 12) {
                if segments.isEmpty {
                    Text(L10n.text(.unknown, language: language))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CleanMacTheme.secondaryText)
                } else {
                    GeometryReader { proxy in
                        HStack(spacing: 0) {
                            ForEach(Array(segments.enumerated()), id: \.offset) { index, segment in
                                segment.color
                                    .frame(width: max(8, proxy.size.width * segment.weight))
                                    .overlay(alignment: .leading) {
                                        Rectangle()
                                            .fill(CleanMacTheme.ink)
                                            .frame(width: 2)
                                            .opacity(index == 0 ? 0 : 1)
                                    }
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

    private func volumeSegments(for snapshot: StorageVolumeSnapshot) -> [DiskSegment] {
        weightedSegments([
            .init(label: L10n.text(.used, language: language), bytes: snapshot.usedCapacityBytes, color: CleanMacTheme.accent),
            .init(label: L10n.text(.free, language: language), bytes: snapshot.availableCapacityBytes, color: Color(red: 0.93, green: 0.91, blue: 0.86))
        ])
    }

    private func candidateSegments(for report: ScanReport) -> [DiskSegment] {
        let totals = Dictionary(grouping: report.candidates, by: \.category)
            .mapValues { candidates in
                candidates.reduce(0) { $0 + $1.sizeBytes }
            }

        let orderedCategories = CandidateCategory.allCases.filter { (totals[$0] ?? 0) > 0 }
        return weightedSegments(
            orderedCategories.map { category in
                .init(
                    label: category.displayName(language: language),
                    bytes: totals[category] ?? 0,
                    color: color(for: category)
                )
            }
        )
    }

    private func weightedSegments(_ inputs: [SegmentInput]) -> [DiskSegment] {
        let total = max(1, inputs.reduce(0) { $0 + $1.bytes })
        return inputs
            .filter { $0.bytes > 0 }
            .map { input in
                DiskSegment(
                    label: input.label,
                    value: Formatters.bytes(input.bytes),
                    color: input.color,
                    weight: CGFloat(input.bytes) / CGFloat(total)
                )
            }
    }

    private func color(for category: CandidateCategory) -> Color {
        switch category {
        case .cache: CleanMacTheme.peach
        case .logs: CleanMacTheme.mint
        case .downloads: CleanMacTheme.purple
        case .trash: CleanMacTheme.accent
        case .temporary: CleanMacTheme.amber
        case .developer: CleanMacTheme.pink
        case .largeFile: Color(red: 0.96, green: 0.72, blue: 0.59)
        case .application: CleanMacTheme.accent
        case .applicationSupport: Color(red: 0.66, green: 0.72, blue: 0.85)
        case .other: Color(red: 0.93, green: 0.91, blue: 0.86)
        }
    }

    private struct SegmentInput {
        var label: String
        var bytes: Int64
        var color: Color
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
                title: L10n.text(.overviewPerformanceTitle, language: language),
                detail: L10n.text(.overviewPerformanceDetail, language: language),
                value: Formatters.bytes(cleanupBytes(for: [.cache, .logs, .temporary, .developer])),
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
                title: L10n.text(.overviewJunkFilesTitle, language: language),
                detail: L10n.text(.overviewJunkFilesDetail, language: language),
                value: Formatters.bytes(store.lastReport?.totalBytes ?? 0),
                asset: .cleanupTrash,
                tint: CleanMacTheme.accent,
                buttonTitle: L10n.text(.results, language: language),
                buttonSymbol: "arrow.right",
                isActive: store.isScanning,
                action: openResults
            )

            OverviewActionCard(
                title: L10n.text(.overviewUserFilesTitle, language: language),
                detail: L10n.text(.overviewUserFilesDetail, language: language),
                value: Formatters.bytes(userFileBytes),
                asset: .duplicates,
                tint: CleanMacTheme.purple,
                buttonTitle: L10n.text(.manage, language: language),
                buttonSymbol: "folder",
                action: openResults
            )
        }
    }

    private var userFileBytes: Int64 {
        if store.selectedSummary.totalBytes > 0 {
            return store.selectedSummary.totalBytes
        }
        return store.duplicateReclaimableBytes
    }

    private func cleanupBytes(for categories: Set<CandidateCategory>) -> Int64 {
        store.candidates
            .filter { categories.contains($0.category) }
            .reduce(0) { $0 + $1.sizeBytes }
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
