import CleanMacCore
import SwiftUI

struct AppUninstallerView: View {
    @ObservedObject var store: CleaningStore
    var language: ResolvedLanguage
    var openResults: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    UninstallerMetricTile(title: L10n.text(.applications, language: language), value: "\(store.uninstallPlans.count)", symbolName: "app")
                    UninstallerMetricTile(title: L10n.text(.potential, language: language), value: Formatters.bytes(store.uninstallReclaimableBytes), symbolName: "shippingbox")
                    UninstallerMetricTile(title: L10n.text(.selected, language: language), value: Formatters.bytes(store.selectedSummary.totalBytes), symbolName: "checkmark.circle")
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(L10n.text(.applications, language: language))
                            .font(.headline)
                        Spacer()
                        Button {
                            store.addApplicationFolderWithOpenPanel()
                        } label: {
                            Label(L10n.text(.add, language: language), systemImage: "plus")
                        }
                    }

                    VStack(spacing: 0) {
                        ForEach(store.appRoots, id: \.self) { root in
                            HStack(spacing: 10) {
                                Image(systemName: "folder")
                                    .foregroundStyle(.secondary)
                                    .frame(width: 18)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(root.lastPathComponent.isEmpty ? root.path : root.lastPathComponent)
                                        .lineLimit(1)
                                    Text(root.path)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Button {
                                    store.removeApplicationRoot(root)
                                } label: {
                                    Image(systemName: "minus.circle")
                                }
                                .buttonStyle(.borderless)
                                .help(L10n.text(.remove, language: language))
                            }
                            .padding(.vertical, 9)
                            .padding(.horizontal, 10)

                            if root != store.appRoots.last {
                                Divider()
                            }
                        }
                    }
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                }

                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Text(L10n.text(.appUninstaller, language: language))
                            .font(.headline)
                        Spacer()
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
                        ProgressView()
                            .controlSize(.small)
                    } else if store.uninstallPlans.isEmpty {
                        ContentUnavailableView(
                            L10n.text(.noApplicationsFound, language: language),
                            systemImage: "app"
                        )
                        .frame(maxWidth: .infinity, minHeight: 180)
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

                                if plan.id != store.uninstallPlans.last?.id {
                                    Divider()
                                }
                            }
                        }
                        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(16)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

private struct UninstallPlanRow: View {
    var plan: AppUninstallPlan
    var language: ResolvedLanguage
    var selectItems: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "app")
                .foregroundStyle(.secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(plan.appName)
                    .font(.headline)
                    .lineLimit(1)
                Text(plan.bundleIdentifier)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text("\(plan.supportCandidates.count) support items | \(Formatters.bytes(plan.movableReclaimableBytes))")
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

private struct UninstallerMetricTile: View {
    var title: String
    var value: String
    var symbolName: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbolName)
                .font(.title3)
                .foregroundStyle(.secondary)
                .frame(width: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title3.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(minWidth: 150, maxWidth: .infinity, minHeight: 76)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}
