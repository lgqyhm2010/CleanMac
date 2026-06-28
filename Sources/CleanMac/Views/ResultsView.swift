import CleanMacCore
import SwiftUI

struct ResultsView: View {
    @ObservedObject var store: CleaningStore
    @State private var confirmTrash = false

    var body: some View {
        VStack(spacing: 0) {
            resultsHeader
                .padding(16)

            Divider()

            if store.candidates.isEmpty {
                ContentUnavailableView(
                    "No Candidates",
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

                    TableColumn("Name") { candidate in
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

                    TableColumn("Category") { candidate in
                        Text(candidate.category.displayName)
                    }
                    .width(min: 110, ideal: 130)

                    TableColumn("Risk") { candidate in
                        Text(candidate.risk.displayName)
                            .foregroundStyle(riskColor(candidate.risk))
                    }
                    .width(min: 110, ideal: 130)

                    TableColumn("Size") { candidate in
                        Text(Formatters.bytes(candidate.sizeBytes))
                            .monospacedDigit()
                    }
                    .width(min: 90, ideal: 110)
                }
            }

            Divider()

            CandidateDetailView(candidate: store.selectedCandidate)
                .padding(16)
        }
        .alert("Move selected items to Trash?", isPresented: $confirmTrash) {
            Button("Cancel", role: .cancel) {}
            Button("Move to Trash", role: .destructive) {
                store.cleanSelected()
            }
        } message: {
            Text("\(store.selectedSummary.selectedCount) items, \(Formatters.bytes(store.selectedSummary.totalBytes))")
        }
    }

    private var resultsHeader: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                Text("\(store.candidates.count) Candidates")
                    .font(.headline)
                Text("\(Formatters.bytes(store.selectedSummary.totalBytes)) selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                store.selectAll()
            } label: {
                Label("Select All", systemImage: "checklist.checked")
            }
            .disabled(store.candidates.isEmpty)

            Button {
                store.clearSelection()
            } label: {
                Label("Clear", systemImage: "xmark.circle")
            }
            .disabled(store.selectedSummary.selectedCount == 0)

            Button(role: .destructive) {
                confirmTrash = true
            } label: {
                Label(store.isCleaning ? "Moving" : "Move to Trash", systemImage: "trash")
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

    var body: some View {
        Group {
            if let candidate {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label(candidate.category.displayName, systemImage: candidate.category.symbolName)
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
                        Label(candidate.risk.displayName, systemImage: "exclamationmark.triangle")
                        Label(Formatters.date(candidate.modifiedAt), systemImage: "calendar")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    if !candidate.reasons.isEmpty {
                        Text(candidate.reasons.joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("No item selected")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(minHeight: 110, alignment: .topLeading)
    }
}
