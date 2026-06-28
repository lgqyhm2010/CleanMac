import CleanMacCore
import SwiftUI

struct AIReviewView: View {
    @ObservedObject var store: CleaningStore
    @Binding var aiExecutable: String
    @Binding var aiArguments: String
    var language: ResolvedLanguage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            CleanMacHeroHeader(
                title: L10n.text(.aiReview, language: language),
                subtitle: "\(L10n.selectedHeadline(store.selectedSummary.selectedCount, language: language)) | \(Formatters.bytes(store.selectedSummary.totalBytes))",
                symbolName: "sparkles",
                tint: CleanMacTheme.sectionTint(.aiReview),
                isActive: store.isReviewingWithAI
            ) {
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

            if store.isReviewingWithAI {
                CleanMacProgressState(
                    title: L10n.text(.reviewing, language: language),
                    symbolName: "sparkles",
                    tint: CleanMacTheme.sectionTint(.aiReview)
                )
            } else if store.aiOutput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                CleanMacEmptyState(
                    title: L10n.text(.noReview, language: language),
                    symbolName: "sparkles",
                    tint: CleanMacTheme.sectionTint(.aiReview)
                )
            } else {
                TextEditor(text: $store.aiOutput)
                    .font(.system(.body, design: .monospaced))
                    .padding(12)
                    .transition(.opacity)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.35))
        .animation(CleanMacMotion.allowed(reduceMotion, CleanMacMotion.quick), value: store.isReviewingWithAI)
    }
}
