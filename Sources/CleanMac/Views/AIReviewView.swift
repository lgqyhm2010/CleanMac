import SwiftUI

struct AIReviewView: View {
    @ObservedObject var store: CleaningStore
    @Binding var aiExecutable: String
    @Binding var aiArguments: String

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section("Command") {
                    TextField("Executable", text: $aiExecutable)
                    TextField("Arguments", text: $aiArguments)
                }

                Section("Question") {
                    TextEditor(text: $store.aiQuestion)
                        .font(.body)
                        .frame(minHeight: 80)
                }
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
            .frame(height: 230)

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(store.selectedSummary.selectedCount) Selected")
                        .font(.headline)
                    Text(Formatters.bytes(store.selectedSummary.totalBytes))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    store.askAI(executable: aiExecutable, argumentsText: aiArguments)
                } label: {
                    Label(store.isReviewingWithAI ? "Reviewing" : "Ask AI", systemImage: "sparkles")
                }
                .buttonStyle(.borderedProminent)
                .disabled(store.selectedSummary.selectedCount == 0 || store.isReviewingWithAI)
            }
            .padding(16)

            Divider()

            if store.isReviewingWithAI {
                VStack(spacing: 10) {
                    ProgressView()
                    Text("Reviewing")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.aiOutput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                ContentUnavailableView(
                    "No Review",
                    systemImage: "sparkles"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TextEditor(text: $store.aiOutput)
                    .font(.system(.body, design: .monospaced))
                    .padding(12)
            }
        }
    }
}
