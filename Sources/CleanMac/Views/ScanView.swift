import SwiftUI

struct ScanView: View {
    @ObservedObject var store: CleaningStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                SummaryStrip(store: store)

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Folders")
                            .font(.headline)
                        Spacer()
                        Button {
                            store.addFolderWithOpenPanel()
                        } label: {
                            Label("Add", systemImage: "plus")
                        }
                    }

                    VStack(spacing: 0) {
                        ForEach(store.roots, id: \.self) { root in
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
                                    store.removeRoot(root)
                                } label: {
                                    Image(systemName: "minus.circle")
                                }
                                .buttonStyle(.borderless)
                                .help("Remove")
                            }
                            .padding(.vertical, 9)
                            .padding(.horizontal, 10)

                            if root != store.roots.last {
                                Divider()
                            }
                        }
                    }
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("Scan Options")
                        .font(.headline)

                    Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 12) {
                        GridRow {
                            Text("Minimum Size")
                            Slider(value: $store.minimumSizeMegabytes, in: 0...200, step: 1)
                            Text("\(Int(store.minimumSizeMegabytes)) MB")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }

                        GridRow {
                            Text("Large File")
                            Slider(value: $store.largeFileThresholdMegabytes, in: 50...5_000, step: 50)
                            Text("\(Int(store.largeFileThresholdMegabytes)) MB")
                                .foregroundStyle(.secondary)
                                .monospacedDigit()
                        }

                        GridRow {
                            Text("Hidden Files")
                            Toggle("Include", isOn: $store.includeHiddenFiles)
                            Text("")
                        }
                    }

                    HStack {
                        Button {
                            store.scan()
                        } label: {
                            Label(store.isScanning ? "Scanning" : "Scan", systemImage: "magnifyingglass")
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(store.isScanning || store.roots.isEmpty)

                        if store.isScanning {
                            ProgressView()
                                .controlSize(.small)
                        }

                        Spacer()

                        StatusText(store: store)
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

private struct SummaryStrip: View {
    @ObservedObject var store: CleaningStore

    var body: some View {
        HStack(spacing: 12) {
            MetricTile(title: "Candidates", value: "\(store.candidates.count)", symbolName: "doc.on.doc")
            MetricTile(title: "Potential", value: Formatters.bytes(store.lastReport?.totalBytes ?? 0), symbolName: "internaldrive")
            MetricTile(title: "Selected", value: Formatters.bytes(store.selectedSummary.totalBytes), symbolName: "checkmark.circle")
        }
    }
}

private struct MetricTile: View {
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

private struct StatusText: View {
    @ObservedObject var store: CleaningStore

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            Text(store.statusMessage)
                .font(.callout)
            if let error = store.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .lineLimit(2)
            }
        }
        .foregroundStyle(.secondary)
    }
}
