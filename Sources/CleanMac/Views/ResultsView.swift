import CleanMacCore
import SwiftUI

struct ResultsView: View {
    @ObservedObject var store: CleaningStore
    var language: ResolvedLanguage
    @State private var confirmTrash = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            CleanMacPanel(padding: 14) {
                resultsHeader
            }
                .padding(16)

            Divider()

            if store.candidates.isEmpty {
                if store.isScanning {
                    CleanMacProgressState(
                        title: L10n.text(.scanning, language: language),
                        symbolName: "magnifyingglass",
                        tint: CleanMacTheme.accent
                    )
                } else {
                    CleanMacEmptyState(
                        title: L10n.text(.noCandidates, language: language),
                        symbolName: "checkmark.seal",
                        tint: CleanMacTheme.mint
                    )
                }
            } else {
                Table(store.candidates, selection: $store.selectedCandidateID) {
                    TableColumn("") { candidate in
                        Toggle("", isOn: Binding(
                            get: { store.selection.contains(candidate) },
                            set: { store.toggle(candidate, selected: $0) }
                        ))
                        .labelsHidden()
                    }
                    .width(34)

                    TableColumn(L10n.text(.name, language: language)) { candidate in
                        HStack(spacing: 8) {
                            Image(systemName: candidate.category.symbolName)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(categoryTint(candidate.category))
                                .frame(width: 18)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(candidate.url.lastPathComponent)
                                    .lineLimit(1)
                                Text(candidate.url.deletingLastPathComponent().path)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }

                    TableColumn(L10n.text(.category, language: language)) { candidate in
                        Text(candidate.category.displayName(language: language))
                    }
                    .width(min: 110, ideal: 130)

                    TableColumn(L10n.text(.risk, language: language)) { candidate in
                        StatusBadge(
                            text: candidate.risk.displayName(language: language),
                            symbolName: "exclamationmark.triangle",
                            tint: CleanMacTheme.riskColor(candidate.risk)
                        )
                    }
                    .width(min: 120, ideal: 140)

                    TableColumn(L10n.text(.protection, language: language)) { candidate in
                        StatusBadge(
                            text: candidate.protection.displayName(language: language),
                            symbolName: candidate.protection.symbolName,
                            tint: CleanMacTheme.protectionColor(candidate.protection)
                        )
                    }
                    .width(min: 140, ideal: 165)

                    TableColumn(L10n.text(.size, language: language)) { candidate in
                        Text(Formatters.bytes(candidate.sizeBytes))
                            .monospacedDigit()
                    }
                    .width(min: 90, ideal: 110)
                }
            }

            Divider()

            CleanMacPanel(padding: 14) {
                CandidateDetailView(
                    candidate: store.selectedCandidate,
                    duplicateGroup: store.duplicateGroup(containing: store.selectedCandidate),
                    uninstallPlan: store.uninstallPlan(containing: store.selectedCandidate),
                    language: language
                )
                .id(store.selectedCandidate?.id ?? "empty")
                .transition(.opacity)
            }
                .padding(16)
        }
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.35))
        .animation(CleanMacMotion.allowed(reduceMotion, CleanMacMotion.quick), value: store.candidates.count)
        .animation(CleanMacMotion.allowed(reduceMotion, CleanMacMotion.quick), value: store.selectedCandidateID)
        .alert(L10n.text(.moveSelectedItemsToTrash, language: language), isPresented: $confirmTrash) {
            Button(L10n.text(.cancel, language: language), role: .cancel) {}
            Button(L10n.text(.moveToTrash, language: language), role: .destructive) {
                store.cleanSelected()
            }
        } message: {
            Text(L10n.moveToTrashSummary(
                selectedCount: store.selectedSummary.selectedCount,
                protectedCount: store.selectedProtectedCandidates.count,
                totalBytes: store.selectedSummary.totalBytes,
                language: language
            ))
        }
    }

    private var resultsHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                CleanMacPulseIcon(
                    symbolName: "list.bullet.rectangle",
                    tint: CleanMacTheme.sectionTint(.results),
                    isActive: store.isCleaning || store.isScanning
                )
                .font(.title3)
                .frame(width: 38, height: 38)

                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.candidatesHeadline(store.candidates.count, language: language))
                        .font(.headline)
                    Text(selectedDetailText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                StatusBadge(
                    text: L10n.status(store.status, language: language),
                    symbolName: CleanMacTheme.statusSymbol(store.status),
                    tint: CleanMacTheme.statusColor(store.status),
                    isActive: store.isCleaning || store.isScanning
                )
            }

            HStack(spacing: 10) {
                Spacer(minLength: 0)

                Button {
                    store.selectAll()
                } label: {
                    Label(L10n.text(.selectAll, language: language), systemImage: "checklist.checked")
                }
                .disabled(store.candidates.isEmpty)

                Button {
                    store.selectDuplicateCopies()
                } label: {
                    Label(L10n.text(.selectDuplicateCopies, language: language), systemImage: "doc.on.doc")
                }
                .disabled(store.movableDuplicateCandidates.isEmpty)

                Button {
                    store.clearSelection()
                } label: {
                    Label(L10n.text(.clear, language: language), systemImage: "xmark.circle")
                }
                .disabled(store.selectedSummary.selectedCount == 0)

                Button(role: .destructive) {
                    confirmTrash = true
                } label: {
                    Label(
                        store.isCleaning ? L10n.text(.moving, language: language) : L10n.text(.moveToTrash, language: language),
                        systemImage: "trash"
                    )
                }
                .disabled(store.selectedMovableCandidates.isEmpty || store.isCleaning)
            }
        }
    }

    private var selectedDetailText: String {
        let base = "\(Formatters.bytes(store.selectedSummary.totalBytes)) \(L10n.text(.selected, language: language).lowercased())"
        let protectedCount = store.selectedProtectedCandidates.count
        guard protectedCount > 0 else { return base }
        return "\(base) · \(L10n.protectedItemCount(protectedCount, language: language))"
    }

    private func categoryTint(_ category: CandidateCategory) -> Color {
        switch category {
        case .cache, .temporary:
            CleanMacTheme.accent
        case .logs, .developer:
            Color.indigo
        case .downloads, .largeFile:
            CleanMacTheme.amber
        case .trash:
            CleanMacTheme.danger
        case .application, .applicationSupport:
            CleanMacTheme.mint
        case .other:
            .secondary
        }
    }
}

private struct CandidateDetailView: View {
    var candidate: CleaningCandidate?
    var duplicateGroup: DuplicateFileGroup?
    var uninstallPlan: AppUninstallPlan?
    var language: ResolvedLanguage

    var body: some View {
        Group {
            if let candidate {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        CleanMacPulseIcon(
                            symbolName: candidate.category.symbolName,
                            tint: CleanMacTheme.riskColor(candidate.risk),
                            isActive: false
                        )
                        .font(.headline)
                        .frame(width: 32, height: 32)

                        Text(candidate.category.displayName(language: language))
                            .font(.headline)
                        Spacer()
                        Text(Formatters.bytes(candidate.sizeBytes))
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                    }

                    Text(candidate.url.path)
                        .font(.callout)
                        .textSelection(.enabled)
                        .lineLimit(2)

                    HStack(spacing: 18) {
                        StatusBadge(
                            text: candidate.risk.displayName(language: language),
                            symbolName: "exclamationmark.triangle",
                            tint: CleanMacTheme.riskColor(candidate.risk)
                        )
                        StatusBadge(
                            text: candidate.protection.displayName(language: language),
                            symbolName: candidate.protection.symbolName,
                            tint: CleanMacTheme.protectionColor(candidate.protection)
                        )
                        Label(Formatters.date(candidate.modifiedAt, language: language), systemImage: "calendar")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    if !candidate.reasons.isEmpty {
                        Text(candidate.reasons.map { L10n.scanReason($0, language: language) }.joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if !candidate.userVisibleRules.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.text(.rules, language: language))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            ForEach(candidate.userVisibleRules, id: \.self) { rule in
                                Label(rule, systemImage: "list.bullet.clipboard")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }

                    if let duplicateGroup {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.text(.duplicateGroup, language: language))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            Label(
                                L10n.duplicateGroupDetail(duplicateGroup, language: language),
                                systemImage: "doc.on.doc"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                        }
                    }

                    if let uninstallPlan {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.text(.appUninstaller, language: language))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)

                            Label(
                                L10n.appUninstallPlanDetail(uninstallPlan, language: language),
                                systemImage: "app.badge"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                        }
                    }
                }
            } else {
                Text(L10n.text(.noItemSelected, language: language))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(minHeight: 110, alignment: .topLeading)
    }
}
