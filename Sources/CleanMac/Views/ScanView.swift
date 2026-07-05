import CleanMacCore
import SwiftUI

struct ScanView: View {
    @ObservedObject var store: CleaningStore
    var language: ResolvedLanguage
    var openResults: () -> Void = {}
    var openAIReview: () -> Void = {}
    var openSettings: () -> Void = {}
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        CleanMacPage(accent: CleanMacTheme.accent) {
            DashboardHeaderRow(language: language)

            DiskOverviewDashboardCard(store: store, language: language)

            DashboardMetricRow(store: store, language: language, openResults: openResults)

            DashboardScanCTA(store: store, language: language)

            OverviewFeatureGrid(
                store: store,
                language: language,
                openResults: openResults,
                openAIReview: openAIReview,
                openSettings: openSettings
            )

            TrustBadgeStrip(language: language)

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

private struct DashboardHeaderRow: View {
    var language: ResolvedLanguage

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            HStack(spacing: 12) {
                CleanMacFeatureImage(asset: .diskOverview, tint: CleanMacTheme.accent)
                    .frame(width: 46, height: 46)

                Text(L10n.text(.sidebarDiskOverviewTitle, language: language))
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundStyle(CleanMacTheme.ink)
                    .lineLimit(1)
            }

            Spacer(minLength: 12)

            DashboardPrivacyBadge(language: language)
        }
    }
}

private struct DashboardPrivacyBadge: View {
    var language: ResolvedLanguage

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: "checkmark.shield.fill")
                .font(.title3.weight(.bold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(CleanMacTheme.mint)
                .frame(width: 30, height: 30)
                .background(CleanMacTheme.mint.opacity(0.18), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(CleanMacTheme.ink, lineWidth: 1.4)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.text(.privateByDesign, language: language))
                    .font(.caption.weight(.bold))
                Text("\(L10n.text(.trustNoTelemetry, language: language)). \(L10n.text(.trustNoCloudUpload, language: language)).")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(CleanMacTheme.secondaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.76)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(CleanMacTheme.paper, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(CleanMacTheme.mint.opacity(0.85), lineWidth: 1.5)
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

private struct DiskOverviewDashboardCard: View {
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
        CleanMacPanel(padding: 18, tint: CleanMacTheme.accent) {
            HStack(alignment: .center, spacing: 18) {
                VStack(spacing: 8) {
                    CleanMacFeatureImage(asset: .diskOverview, tint: CleanMacTheme.accent, isActive: store.isScanning)
                        .frame(width: 96, height: 96)
                    Text(volumeCapacityLabel)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(CleanMacTheme.secondaryText)
                        .lineLimit(1)
                }
                .frame(width: 132)

                Rectangle()
                    .fill(CleanMacTheme.sidebarDivider)
                    .frame(width: 1, height: 132)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Text(volumeName)
                            .font(.title2.weight(.bold))
                            .lineLimit(1)
                        StatusBadge(
                            text: store.isScanning ? L10n.text(.scanning, language: language) : L10n.text(.healthy, language: language),
                            symbolName: store.isScanning ? "magnifyingglass" : "checkmark",
                            tint: store.isScanning ? CleanMacTheme.accent : CleanMacTheme.mint,
                            isActive: store.isScanning
                        )
                    }

                    DiskSegmentBar(segments: segments)
                        .frame(height: 30)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 128), spacing: 12)], alignment: .leading, spacing: 8) {
                        ForEach(segments) { segment in
                            SegmentLegend(segment: segment)
                        }
                    }
                }

                Spacer(minLength: 8)

                VStack(alignment: .trailing, spacing: 8) {
                    Text(primaryValue)
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .minimumScaleFactor(0.68)
                        .lineLimit(1)
                        .monospacedDigit()
                    Text(primaryCaption)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(CleanMacTheme.secondaryText)
                    Button {
                        store.scan()
                    } label: {
                        Label(
                            store.isScanning ? L10n.text(.scanning, language: language) : L10n.text(.scan, language: language),
                            systemImage: "magnifyingglass"
                        )
                        .frame(minWidth: 132)
                    }
                    .buttonStyle(CleanMacRaisedButtonStyle(tint: CleanMacTheme.accent, prominent: true))
                    .disabled(store.isScanning || store.roots.isEmpty)
                }
                .frame(width: 174, alignment: .trailing)
            }
        }
    }

    private var volumeName: String {
        store.volumeSnapshot?.name ?? L10n.text(.unknown, language: language)
    }

    private var volumeCapacityLabel: String {
        guard let snapshot = store.volumeSnapshot else { return L10n.text(.unknown, language: language) }
        return Formatters.bytes(snapshot.totalCapacityBytes)
    }

    private var primaryValue: String {
        if let report = store.lastReport, report.totalBytes > 0 {
            return Formatters.bytes(report.totalBytes)
        }
        guard let snapshot = store.volumeSnapshot else { return Formatters.bytes(0) }
        return Formatters.bytes(snapshot.availableCapacityBytes)
    }

    private var primaryCaption: String {
        store.lastReport == nil ? L10n.text(.free, language: language) : L10n.text(.potential, language: language)
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

private struct DiskSegmentBar: View {
    var segments: [DiskSegment]

    var body: some View {
        GeometryReader { proxy in
            if segments.isEmpty {
                Capsule()
                    .fill(CleanMacTheme.chrome)
                    .overlay {
                        Capsule()
                            .strokeBorder(CleanMacTheme.ink, lineWidth: 2.5)
                    }
            } else {
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
                .shadow(color: CleanMacTheme.ink.opacity(0.28), radius: 0, x: 2, y: 2)
            }
        }
    }
}

private struct SegmentLegend: View {
    var segment: DiskSegment

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(segment.color)
                .frame(width: 10, height: 10)
                .overlay {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .strokeBorder(CleanMacTheme.ink, lineWidth: 1.2)
                }
            Text(segment.label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CleanMacTheme.secondaryText)
                .lineLimit(1)
            Text(segment.value)
                .font(.caption.weight(.bold))
                .foregroundStyle(CleanMacTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.76)
        }
    }
}

private struct DashboardMetricRow: View {
    @ObservedObject var store: CleaningStore
    var language: ResolvedLanguage
    var openResults: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            MetricTileView(
                title: L10n.text(.used, language: language),
                value: Formatters.bytes(store.volumeSnapshot?.usedCapacityBytes ?? 0),
                symbolName: "chart.pie",
                asset: .diskOverview,
                tint: CleanMacTheme.accent,
                isActive: store.isScanning
            )
            MetricTileView(
                title: L10n.text(.potential, language: language),
                value: Formatters.bytes(store.lastReport?.totalBytes ?? store.selectedSummary.totalBytes),
                symbolName: "trash",
                asset: .cleanupTrash,
                tint: CleanMacTheme.mint
            )
            MetricTileView(
                title: L10n.text(.candidates, language: language),
                value: "\(store.lastReport?.scannedFileCount ?? store.candidates.count)",
                symbolName: "doc.on.doc",
                asset: .duplicates,
                tint: CleanMacTheme.amber
            )
        }
    }
}

private struct DashboardScanCTA: View {
    @ObservedObject var store: CleaningStore
    var language: ResolvedLanguage

    var body: some View {
        CleanMacPanel(padding: 14, tint: CleanMacTheme.accent) {
            HStack(spacing: 16) {
                CleanMacFeatureImage(asset: .mascot, tint: CleanMacTheme.accent, isActive: store.isScanning)
                    .frame(width: 76, height: 76)

                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.text(.dashboardReadyToScan, language: language))
                        .font(.title3.weight(.bold))
                        .lineLimit(1)
                    ScanTrustChecklist(language: language)
                }

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 5) {
                    Button {
                        store.scan()
                    } label: {
                        Label(
                            store.isScanning ? L10n.text(.scanning, language: language) : L10n.text(.scan, language: language),
                            systemImage: "sparkles"
                        )
                        .frame(minWidth: 170)
                    }
                    .buttonStyle(CleanMacRaisedButtonStyle(tint: CleanMacTheme.accent, prominent: true))
                    .disabled(store.isScanning || store.roots.isEmpty)

                    Text(L10n.text(.dashboardQuickSafePrivate, language: language))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CleanMacTheme.secondaryText)
                }
            }
        }
    }
}

private struct ScanTrustChecklist: View {
    var language: ResolvedLanguage

    var body: some View {
        HStack(spacing: 14) {
            ScanTrustChecklistItem(title: L10n.text(.trustMoveToTrash, language: language))
            ScanTrustChecklistItem(title: L10n.text(.trustLocalAI, language: language))
            ScanTrustChecklistItem(title: L10n.text(.trustNoTelemetry, language: language))
        }
    }
}

private struct ScanTrustChecklistItem: View {
    var title: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(CleanMacTheme.mint)
            Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.76)
        }
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

private struct TrustBadgeStrip: View {
    var language: ResolvedLanguage

    var body: some View {
        CleanMacPanel(padding: 12, tint: CleanMacTheme.mint) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 10)], alignment: .leading, spacing: 10) {
                TrustBadgeItem(
                    title: L10n.text(.trustLocalAI, language: language),
                    symbolName: "sparkles",
                    tint: CleanMacTheme.purple
                )
                TrustBadgeItem(
                    title: L10n.text(.trustMoveToTrash, language: language),
                    symbolName: "trash",
                    tint: CleanMacTheme.mint
                )
                TrustBadgeItem(
                    title: L10n.text(.trustNoTelemetry, language: language),
                    symbolName: "shield.checkered",
                    tint: CleanMacTheme.mint
                )
                TrustBadgeItem(
                    title: L10n.text(.trustNoCloudUpload, language: language),
                    symbolName: "icloud.slash",
                    tint: CleanMacTheme.peach
                )
            }
        }
    }
}

private struct TrustBadgeItem: View {
    var title: String
    var symbolName: String
    var tint: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbolName)
                .imageScale(.small)
                .font(.callout.weight(.bold))
                .foregroundStyle(tint)
                .frame(width: 26, height: 26)
                .background(tint.opacity(0.16), in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(CleanMacTheme.ink, lineWidth: 1.4)
                }

            Text(title)
                .font(.caption.weight(.bold))
                .foregroundStyle(CleanMacTheme.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct OverviewFeatureGrid: View {
    @ObservedObject var store: CleaningStore
    var language: ResolvedLanguage
    var openResults: () -> Void
    var openAIReview: () -> Void
    var openSettings: () -> Void

    private static let columns = [
        GridItem(.adaptive(minimum: 180), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: Self.columns, spacing: 12) {
            OverviewActionCard(
                title: L10n.text(.moveToTrash, language: language),
                detail: L10n.text(.overviewJunkFilesDetail, language: language),
                asset: .cleanupTrash,
                tint: CleanMacTheme.mint,
                buttonTitle: L10n.text(.results, language: language),
                buttonSymbol: "checkmark.circle",
                action: openResults
            )

            OverviewActionCard(
                title: L10n.text(.sidebarDuplicatesTitle, language: language),
                detail: L10n.text(.sidebarDuplicatesSubtitle, language: language),
                asset: .duplicates,
                tint: CleanMacTheme.purple,
                buttonTitle: L10n.text(.manage, language: language),
                buttonSymbol: "doc.on.doc",
                action: openResults
            )

            OverviewActionCard(
                title: L10n.text(.aiReview, language: language),
                detail: L10n.text(.sidebarAIReviewSubtitle, language: language),
                asset: .aiReview,
                tint: CleanMacTheme.purple,
                buttonTitle: L10n.text(.askAI, language: language),
                buttonSymbol: "sparkles",
                isActive: store.isReviewingWithAI,
                action: openAIReview
            )

            OverviewActionCard(
                title: L10n.permissionTitle(.fullDiskAccess(), language: language),
                detail: L10n.permissionStatusName(SystemPermissionGuide.fullDiskAccess().status, language: language),
                asset: .permissionShield,
                tint: CleanMacTheme.peach,
                buttonTitle: L10n.text(.openSettings, language: language),
                buttonSymbol: "lock.shield",
                action: openSettings
            )
        }
    }
}
private struct OverviewActionCard: View {
    var title: String
    var detail: String
    var asset: CleanMacIllustrationAsset
    var tint: Color
    var buttonTitle: String
    var buttonSymbol: String
    var isActive = false
    var action: () -> Void

    var body: some View {
        CleanMacPanel(tint: tint) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top, spacing: 10) {
                    CleanMacFeatureImage(asset: asset, tint: tint, isActive: isActive)
                        .frame(width: 54, height: 54)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(title)
                            .font(.headline.weight(.bold))
                            .foregroundStyle(CleanMacTheme.ink)
                            .lineLimit(1)

                        Text(detail)
                            .font(.caption)
                            .foregroundStyle(CleanMacTheme.secondaryText)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)
                            .minimumScaleFactor(0.82)
                    }
                }

                Button(action: action) {
                    Label(buttonTitle, systemImage: buttonSymbol)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(CleanMacRaisedButtonStyle(tint: tint, prominent: true))
            }
            .frame(maxWidth: .infinity, minHeight: 116, alignment: .top)
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
