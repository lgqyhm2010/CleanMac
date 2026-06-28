import SwiftUI

struct ContentView: View {
    @StateObject private var store = CleaningStore()
    @State private var selection: SidebarSection? = .scan
    @AppStorage("aiExecutable") private var aiExecutable = "/usr/bin/env"
    @AppStorage("aiArguments") private var aiArguments = "codex exec"

    var body: some View {
        NavigationSplitView {
            SidebarView(selection: $selection, store: store)
        } detail: {
            Group {
                switch selection ?? .scan {
                case .scan:
                    ScanView(store: store)
                case .results:
                    ResultsView(store: store)
                case .aiReview:
                    AIReviewView(
                        store: store,
                        aiExecutable: $aiExecutable,
                        aiArguments: $aiArguments
                    )
                }
            }
            .navigationTitle((selection ?? .scan).title)
        }
        .toolbar {
            ToolbarItemGroup {
                Button {
                    store.scan()
                    selection = .results
                } label: {
                    Label("Scan", systemImage: "arrow.clockwise")
                }
                .disabled(store.isScanning)

                Button {
                    store.selectAll()
                } label: {
                    Label("Select All", systemImage: "checklist.checked")
                }
                .disabled(store.candidates.isEmpty)

                Button {
                    store.askAI(executable: aiExecutable, argumentsText: aiArguments)
                    selection = .aiReview
                } label: {
                    Label("Ask AI", systemImage: "sparkles")
                }
                .disabled(store.selectedSummary.selectedCount == 0 || store.isReviewingWithAI)
            }
        }
        .focusedSceneValue(\.cleanerActions, CleanerActions(
            scan: {
                store.scan()
                selection = .results
            },
            selectAll: {
                store.selectAll()
            },
            clearSelection: {
                store.clearSelection()
            },
            askAI: {
                store.askAI(executable: aiExecutable, argumentsText: aiArguments)
                selection = .aiReview
            }
        ))
    }
}
