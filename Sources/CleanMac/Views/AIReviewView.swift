import CleanMacCore
import SwiftUI

struct AIReviewView: View {
    @ObservedObject var store: CleaningStore
    var language: ResolvedLanguage
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            CleanMacPageBackground(accent: CleanMacTheme.sectionTint(.aiReview))

            VStack(alignment: .leading, spacing: 14) {
                CleanMacHeroHeader(
                    title: L10n.text(.aiReview, language: language),
                    subtitle: "\(L10n.selectedHeadline(store.selectedSummary.selectedCount, language: language)) | \(Formatters.bytes(store.selectedSummary.totalBytes))",
                    symbolName: "sparkles",
                    asset: .aiReview,
                    tint: CleanMacTheme.sectionTint(.aiReview),
                    isActive: store.isReviewingWithAI
                ) {
                    Button {
                        store.askAI()
                    } label: {
                        Label(
                            store.isReviewingWithAI ? L10n.text(.reviewing, language: language) : L10n.text(.askAI, language: language),
                            systemImage: "sparkles"
                        )
                    }
                    .buttonStyle(CleanMacRaisedButtonStyle(tint: CleanMacTheme.sectionTint(.aiReview), prominent: true))
                    .disabled(store.selectedSummary.selectedCount == 0 || store.isReviewingWithAI || store.selectedAIToolID == nil)
                }

                // The empty-tool state is already shown inline in the panel below, so don't
                // also surface it as a banner — otherwise the same message appears twice
                // (e.g. when Ask AI is triggered from the menu shortcut with no tool found).
                if let error = store.errorMessage, error != .noAIToolDetected {
                    // Bounded like ScanView's error label: a failing CLI can emit a long
                    // merged stderr/stdout detail, which must not crush the layout below.
                    Text(L10n.error(error, language: language))
                        .font(.caption)
                        .foregroundStyle(CleanMacTheme.danger)
                        .lineLimit(4)
                        .textSelection(.enabled)
                }

                CleanMacPanel(tint: CleanMacTheme.sectionTint(.aiReview)) {
                    VStack(alignment: .leading, spacing: 12) {
                        CleanMacSectionHeader(
                            title: L10n.text(.aiTool, language: language),
                            symbolName: "terminal",
                            tint: CleanMacTheme.sectionTint(.aiReview)
                        )

                        if store.detectedAITools.isEmpty {
                            Text(L10n.error(.noAIToolDetected, language: language))
                                .font(.callout)
                                .foregroundStyle(CleanMacTheme.secondaryText)
                        } else {
                            HStack(spacing: 8) {
                                ForEach(store.detectedAITools) { tool in
                                    Button {
                                        store.selectAITool(tool.id)
                                    } label: {
                                        Text(tool.profile.displayName)
                                    }
                                    .buttonStyle(CleanMacRaisedButtonStyle(
                                        tint: CleanMacTheme.sectionTint(.aiReview),
                                        prominent: store.selectedAIToolID == tool.id
                                    ))
                                    .accessibilityAddTraits(store.selectedAIToolID == tool.id ? [.isSelected] : [])
                                }
                            }

                            if let selectedTool = store.detectedAITools.first(where: { $0.id == store.selectedAIToolID }) {
                                CleanMacSectionHeader(
                                    title: L10n.text(.model, language: language),
                                    symbolName: "cpu",
                                    tint: CleanMacTheme.sectionTint(.aiReview)
                                )

                                HStack(spacing: 8) {
                                    ForEach(selectedTool.profile.modelOptions) { option in
                                        Button {
                                            store.selectModel(option.id, for: selectedTool.id)
                                        } label: {
                                            Text(option.flagValue == nil ? L10n.text(.defaultModel, language: language) : option.displayName)
                                        }
                                        .buttonStyle(CleanMacRaisedButtonStyle(
                                            tint: CleanMacTheme.sectionTint(.aiReview),
                                            prominent: store.selectedModelOption(for: selectedTool.id)?.id == option.id
                                        ))
                                        .accessibilityAddTraits(store.selectedModelOption(for: selectedTool.id)?.id == option.id ? [.isSelected] : [])
                                    }
                                }
                            }
                        }

                        CleanMacSectionHeader(
                            title: L10n.text(.question, language: language),
                            symbolName: "text.bubble",
                            tint: CleanMacTheme.sectionTint(.aiReview)
                        )

                        TextEditor(text: $store.aiQuestion)
                            .font(.body)
                            .frame(minHeight: 86)
                            .scrollContentBackground(.hidden)
                            .background(CleanMacTheme.warmPane, in: CleanMacTheme.panelShape)
                            .overlay {
                                CleanMacTheme.panelShape
                                    .strokeBorder(CleanMacTheme.ink.opacity(0.28), lineWidth: 1.5)
                            }
                    }
                }

                CleanMacPanel(tint: CleanMacTheme.sectionTint(.aiReview)) {
                    aiOutputContent
                }
                .frame(maxHeight: .infinity)
            }
            .padding(16)
        }
        .foregroundStyle(CleanMacTheme.ink)
        .animation(CleanMacMotion.allowed(reduceMotion, CleanMacMotion.quick), value: store.isReviewingWithAI)
        .task {
            await store.prepareAIReviewScreen()
        }
    }

    @ViewBuilder
    private var aiOutputContent: some View {
        if store.isReviewingWithAI {
            CleanMacProgressState(
                title: L10n.text(.reviewing, language: language),
                symbolName: "sparkles",
                asset: .aiReview,
                tint: CleanMacTheme.sectionTint(.aiReview)
            )
        } else if store.aiOutput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            CleanMacEmptyState(
                title: L10n.text(.noReview, language: language),
                symbolName: "sparkles",
                asset: .aiReview,
                tint: CleanMacTheme.sectionTint(.aiReview)
            )
        } else {
            TextEditor(text: $store.aiOutput)
                .font(.system(.body, design: .monospaced))
                .scrollContentBackground(.hidden)
                .background(CleanMacTheme.warmPane, in: CleanMacTheme.panelShape)
                .transition(.opacity)
        }
    }
}
