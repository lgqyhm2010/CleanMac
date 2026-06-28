import CleanMacCore
import SwiftUI

struct AppUninstallerView: View {
    @ObservedObject var store: CleaningStore
    var language: ResolvedLanguage
    var openResults: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        CleanMacPage {
            CleanMacHeroHeader(
                title: L10n.text(.appUninstaller, language: language),
                subtitle: appStatusText,
                symbolName: "app.badge",
                tint: CleanMacTheme.mint,
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
                    tint: CleanMacTheme.mint,
                    isActive: store.isScanningApplications
                )
                MetricTileView(
                    title: L10n.text(.potential, language: language),
                    value: Formatters.bytes(store.uninstallReclaimableBytes),
                    symbolName: "shippingbox",
                    tint: CleanMacTheme.accent
                )
                MetricTileView(
                    title: L10n.text(.candidates, language: language),
                    value: "\(uninstallCandidateCount)",
                    symbolName: "list.bullet.rectangle",
                    tint: CleanMacTheme.amber
                )
            }

            CleanMacPanel {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        CleanMacSectionHeader(
                            title: L10n.text(.applications, language: language),
                            symbolName: "folder",
                            tint: CleanMacTheme.mint
                        )
                        Button {
                            store.addApplicationFolderWithOpenPanel()
                        } label: {
                            Label(L10n.text(.add, language: language), systemImage: "plus")
                        }
                    }

                    CleanMacURLList(
                        urls: store.appRoots,
                        tint: CleanMacTheme.mint,
                        remove: store.removeApplicationRoot,
                        language: language
                    )
                }
            }

            CleanMacPanel {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        CleanMacSectionHeader(
                            title: L10n.text(.appUninstaller, language: language),
                            symbolName: "app.badge",
                            tint: CleanMacTheme.mint
                        )
                        Button {
                            store.scanApplications()
                        } label: {
                            Label(
                                store.isScanningApplications ? L10n.text(.scanning, language: language) : L10n.text(.scanApplications, language: language),
                                systemImage: "app.badge"
                            )
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(store.isScanningApplications || store.appRoots.isEmpty)
                    }

                    if store.isScanningApplications {
                        CleanMacProgressState(
                            title: L10n.text(.scanning, language: language),
                            symbolName: "app.badge",
                            tint: CleanMacTheme.mint
                        )
                        .frame(minHeight: 180)
                    } else if store.uninstallPlans.isEmpty {
                        CleanMacEmptyState(
                            title: L10n.text(.noApplicationsFound, language: language),
                            symbolName: "app",
                            tint: CleanMacTheme.mint
                        )
                        .frame(minHeight: 180)
                    } else {
                        VStack(spacing: 0) {
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

                                if plan.id != store.uninstallPlans.last?.id {
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
        store.isScanningApplications ? CleanMacTheme.accent : CleanMacTheme.mint
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
            CleanMacPulseIcon(symbolName: "app", tint: CleanMacTheme.mint, isActive: false)
                .font(.title3)
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 3) {
                Text(plan.appName)
                    .font(.headline)
                    .lineLimit(1)
                Text(plan.bundleIdentifier)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text("\(L10n.candidateCount(plan.supportCandidates.count, language: language)) | \(Formatters.bytes(plan.movableReclaimableBytes))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
