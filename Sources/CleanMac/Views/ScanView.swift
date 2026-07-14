import CleanMacCore
import SwiftUI

struct ScanView: View {
    @Bindable var store: CleaningStore
    var language: ResolvedLanguage
    var openResults: () -> Void = {}
    var openAIReview: () -> Void = {}
    var openSettings: () -> Void = {}
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    // Probing full disk access touches the file system, so it must not run
    // during body evaluation. Seed from the shared cache (placeholder on the
    // very first visit) and let `.task` refresh it off the main actor.
    @State private var fullDiskAccessGuide = FullDiskAccessGuideCache.lastKnownOrPlaceholder

    var body: some View {
        CleanMacPage(accent: CleanMacTheme.accent) {
            DashboardHeaderRow(language: language)

            DiskOverviewDashboardCard(store: store, language: language)

            DashboardMetricRow(store: store, language: language, openResults: openResults)

            DashboardScanCTA(store: store, language: language)

            OverviewFeatureGrid(
                store: store,
                language: language,
                fullDiskAccessGuide: fullDiskAccessGuide,
                openResults: openResults,
                openAIReview: openAIReview,
                openSettings: openSettings
            )

            TrustBadgeStrip(language: language)

            PermissionGuideView(
                guide: fullDiskAccessGuide,
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
                            store.addRoots(FolderOpenPanel.chooseFolders(language: language))
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
                            Slider(value: $store.minimumSizeMegabytes, in: CleaningStore.minimumSizeRange, step: 1)
                            // The label must echo the slider's own unit and step:
                            // ByteCountFormatter is decimal (500 -> "524.3 MB").
                            Text("\(Int(store.minimumSizeMegabytes)) MB")
                                .foregroundStyle(CleanMacTheme.secondaryText)
                                .monospacedDigit()
                        }

                        GridRow {
                            Text(L10n.text(.largeFile, language: language))
                            Slider(value: $store.largeFileThresholdMegabytes, in: CleaningStore.largeFileThresholdRange, step: 50)
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
                        .disabled(store.isBusy || store.roots.isEmpty)

                        if store.isScanning {
                            Button {
                                store.cancelScan()
                            } label: {
                                Label(L10n.text(.cancel, language: language), systemImage: "xmark.circle")
                            }
                            .buttonStyle(CleanMacRaisedButtonStyle(tint: CleanMacTheme.danger))
                            .transition(.opacity)

                            ProgressView()
                                .controlSize(.small)
                                .transition(.opacity)

                            if let scannedFileCount = store.scanProgressCount {
                                Text("· \(scannedFileCount)")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(CleanMacTheme.secondaryText)
                                    .monospacedDigit()
                                    .transition(.opacity)
                            }
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
        .task {
            fullDiskAccessGuide = await FullDiskAccessGuideCache.refresh()
        }
    }
}

private struct StatusText: View {
    let store: CleaningStore
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
