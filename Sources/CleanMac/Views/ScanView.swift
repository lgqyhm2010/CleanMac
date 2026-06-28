import CleanMacCore
import SwiftUI

struct ScanView: View {
    @ObservedObject var store: CleaningStore
    var language: ResolvedLanguage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        CleanMacPage(accent: CleanMacTheme.accent) {
            CleanMacHeroHeader(
                title: L10n.text(.scan, language: language),
                subtitle: L10n.status(store.status, language: language),
                symbolName: "magnifyingglass",
                asset: .diskOverview,
                tint: CleanMacTheme.accent,
                isActive: store.isScanning
            ) {
                StatusText(store: store, language: language)
            }

            SummaryStrip(store: store, language: language)

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
