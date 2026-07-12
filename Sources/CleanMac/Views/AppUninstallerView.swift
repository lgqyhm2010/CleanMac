import CleanMacCore
import SwiftUI

struct AppUninstallerView: View {
    let store: CleaningStore
    var language: ResolvedLanguage
    var openResults: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        CleanMacPage(accent: CleanMacTheme.pink) {
            CleanMacHeroHeader(
                title: L10n.text(.appUninstaller, language: language),
                subtitle: appStatusText,
                symbolName: "app.badge",
                asset: .appUninstall,
                tint: CleanMacTheme.pink,
                isActive: store.isScanningApplications
            ) {
                StatusBadge(
                    text: appStatusText,
                    symbolName: appStatusSymbol,
                    tint: appStatusTint,
                    isActive: store.isScanningApplications
                )
            }

            HStack(spacing: 12) {
                MetricTileView(
                    title: L10n.text(.applications, language: language),
                    value: "\(store.uninstallPlans.count)",
                    symbolName: "app",
                    asset: .appUninstall,
                    tint: CleanMacTheme.pink,
                    isActive: store.isScanningApplications
                )
                MetricTileView(
                    title: L10n.text(.potential, language: language),
                    value: Formatters.bytes(store.uninstallReclaimableBytes),
                    symbolName: "shippingbox",
                    asset: .diskOverview,
                    tint: CleanMacTheme.accent
                )
                MetricTileView(
                    title: L10n.text(.candidates, language: language),
                    value: "\(uninstallCandidateCount)",
                    symbolName: "list.bullet.rectangle",
                    asset: .duplicates,
                    tint: CleanMacTheme.amber
                )
            }

            CleanMacPanel(tint: CleanMacTheme.pink) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        CleanMacSectionHeader(
                            title: L10n.text(.applications, language: language),
                            symbolName: "folder",
                            tint: CleanMacTheme.pink
                        )
                        Button {
                            store.addApplicationRoots(FolderOpenPanel.chooseFolders(language: language))
                        } label: {
                            Label(L10n.text(.add, language: language), systemImage: "plus")
                        }
                    }

                    CleanMacURLList(
                        urls: store.appRoots,
                        tint: CleanMacTheme.pink,
                        remove: store.removeApplicationRoot,
                        language: language
                    )
                }
            }

            CleanMacPanel(tint: CleanMacTheme.pink) {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        CleanMacSectionHeader(
                            title: L10n.text(.appUninstaller, language: language),
                            symbolName: "app.badge",
                            tint: CleanMacTheme.pink
                        )
                        Button {
                            store.scanApplications()
                        } label: {
                            Label(
                                store.isScanningApplications ? L10n.text(.scanning, language: language) : L10n.text(.scanApplications, language: language),
                                systemImage: "app.badge"
                            )
                        }
                        .buttonStyle(CleanMacRaisedButtonStyle(tint: CleanMacTheme.pink, prominent: true))
                        .disabled(store.isBusy || store.appRoots.isEmpty)

                        if store.isScanningApplications {
                            Button {
                                store.cancelScan()
                            } label: {
                                Label(L10n.text(.cancel, language: language), systemImage: "xmark.circle")
                            }
                            .buttonStyle(CleanMacRaisedButtonStyle(tint: CleanMacTheme.danger))
                            .transition(.opacity)
                        }
                    }

                    if store.isScanningApplications {
                        CleanMacProgressState(
                            title: L10n.text(.scanning, language: language),
                            symbolName: "app.badge",
                            asset: .appUninstall,
                            tint: CleanMacTheme.pink
                        )
                        .frame(minHeight: 180)
                    } else if store.uninstallPlans.isEmpty {
                        CleanMacEmptyState(
                            title: L10n.text(.noApplicationsFound, language: language),
                            symbolName: "app",
                            asset: .appUninstall,
                            tint: CleanMacTheme.pink
                        )
                        .frame(minHeight: 180)
                    } else {
                        let lastPlanID = store.uninstallPlans.last?.id
                        LazyVStack(spacing: 0) {
                            ForEach(store.uninstallPlans) { plan in
                                UninstallPlanRow(
                                    plan: plan,
                                    language: language,
                                    selectItems: {
                                        store.selectUninstallItems(for: plan)
                                        openResults()
                                    }
                                )
                                .transition(.cleanMacInsert)

                                if plan.id != lastPlanID {
                                    Divider()
                                }
                            }
                        }
                    }
                }
                .animation(CleanMacMotion.allowed(reduceMotion, CleanMacMotion.quick), value: store.isScanningApplications)
            }
        }
    }

    private var appStatusText: String {
        if store.isScanningApplications {
            return L10n.text(.scanning, language: language)
        }

        guard !store.uninstallPlans.isEmpty else {
            return L10n.status(.ready, language: language)
        }

        return L10n.uninstallPlanCount(store.uninstallPlans.count, language: language)
    }

    private var appStatusSymbol: String {
        if store.isScanningApplications {
            return "app.badge"
        }

        return store.uninstallPlans.isEmpty ? "checkmark.circle" : "list.bullet.rectangle"
    }

    private var appStatusTint: Color {
        store.isScanningApplications ? CleanMacTheme.accent : CleanMacTheme.pink
    }

    private var uninstallCandidateCount: Int {
        store.uninstallPlans.reduce(0) { $0 + $1.allCandidates.count }
    }
}

private struct UninstallPlanRow: View {
    var plan: AppUninstallPlan
    var language: ResolvedLanguage
    var selectItems: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            CleanMacFeatureImage(asset: .appUninstall, tint: CleanMacTheme.pink)
                .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text(plan.appName)
                    .font(.headline)
                    .lineLimit(1)
                Text(plan.bundleIdentifier)
                    .font(.caption)
                    .foregroundStyle(CleanMacTheme.secondaryText)
                    .lineLimit(1)
                Text(Formatters.bytes(plan.movableReclaimableBytes))
                    .font(.caption)
                    .foregroundStyle(CleanMacTheme.secondaryText)
                    .lineLimit(1)
            }

            Spacer()

            Button {
                selectItems()
            } label: {
                Label(L10n.text(.selectUninstallItems, language: language), systemImage: "checklist.checked")
            }
            .disabled(plan.movableCandidates.isEmpty)
        }
        .padding(12)
    }
}
