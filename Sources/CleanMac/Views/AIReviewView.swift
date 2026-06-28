import CleanMacCore
import SwiftUI

struct AIReviewView: View {
    @ObservedObject var store: CleaningStore
    @Binding var aiExecutable: String
    @Binding var aiArguments: String
    var language: ResolvedLanguage

    var body: some View {
        VStack(spacing: 0) {
            Form {
                Section(L10n.text(.command, language: language)) {
                    TextField(L10n.text(.executable, language: language), text: $aiExecutable)
                    TextField(L10n.text(.arguments, language: language), text: $aiArguments)
                }

                Section(L10n.text(.question, language: language)) {
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
                    Text(L10n.selectedHeadline(store.selectedSummary.selectedCount, language: language))
                        .font(.headline)
                    Text(Formatters.bytes(store.selectedSummary.totalBytes))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    store.askAI(executable: aiExecutable, argumentsText: aiArguments)
                } label: {
                    Label(
                        store.isReviewingWithAI ? L10n.text(.reviewing, language: language) : L10n.text(.askAI, language: language),
                        systemImage: "sparkles"
                    )
                }
                .buttonStyle(.borderedProminent)
                .disabled(store.selectedSummary.selectedCount == 0 || store.isReviewingWithAI)
            }
            .padding(16)

            Divider()

            if store.isReviewingWithAI {
                VStack(spacing: 10) {
                    ProgressView()
                    Text(L10n.text(.reviewing, language: language))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.aiOutput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                ContentUnavailableView(
                    L10n.text(.noReview, language: language),
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
