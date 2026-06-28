import CleanMacCore
import SwiftUI

struct ResultsView: View {
    @ObservedObject var store: CleaningStore
    var language: ResolvedLanguage
    @State private var confirmTrash = false

    var body: some View {
        VStack(spacing: 0) {
            resultsHeader
                .padding(16)

            Divider()

            if store.candidates.isEmpty {
                ContentUnavailableView(
                    L10n.text(.noCandidates, language: language),
                    systemImage: store.isScanning ? "magnifyingglass" : "checkmark.seal"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                                .foregroundStyle(.secondary)
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
                        Text(candidate.risk.displayName(language: language))
                            .foregroundStyle(riskColor(candidate.risk))
                    }
                    .width(min: 110, ideal: 130)

                    TableColumn(L10n.text(.size, language: language)) { candidate in
                        Text(Formatters.bytes(candidate.sizeBytes))
                            .monospacedDigit()
                    }
                    .width(min: 90, ideal: 110)
                }
            }

            Divider()

            CandidateDetailView(candidate: store.selectedCandidate, language: language)
                .padding(16)
        }
        .alert(L10n.text(.moveSelectedItemsToTrash, language: language), isPresented: $confirmTrash) {
            Button(L10n.text(.cancel, language: language), role: .cancel) {}
            Button(L10n.text(.moveToTrash, language: language), role: .destructive) {
                store.cleanSelected()
            }
        } message: {
            Text("\(store.selectedSummary.selectedCount) items, \(Formatters.bytes(store.selectedSummary.totalBytes))")
        }
    }

    private var resultsHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text(L10n.candidatesHeadline(store.candidates.count, language: language))
                    .font(.headline)
                Text("\(Formatters.bytes(store.selectedSummary.totalBytes)) \(L10n.text(.selected, language: language).lowercased())")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                store.selectAll()
            } label: {
                Label(L10n.text(.selectAll, language: language), systemImage: "checklist.checked")
            }
            .disabled(store.candidates.isEmpty)

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
            .disabled(store.selectedSummary.selectedCount == 0 || store.isCleaning)
        }
    }

    private func riskColor(_ risk: DeletionRisk) -> Color {
        switch risk {
        case .usuallySafe: .green
        case .reviewRecommended: .orange
        case .beCareful: .red
        }
    }
}

private struct CandidateDetailView: View {
    var candidate: CleaningCandidate?
    var language: ResolvedLanguage

    var body: some View {
        Group {
            if let candidate {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label(candidate.category.displayName(language: language), systemImage: candidate.category.symbolName)
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
                        Label(candidate.risk.displayName(language: language), systemImage: "exclamationmark.triangle")
                        Label(Formatters.date(candidate.modifiedAt, language: language), systemImage: "calendar")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    if !candidate.reasons.isEmpty {
                        Text(candidate.reasons.map { L10n.scanReason($0, language: language) }.joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
