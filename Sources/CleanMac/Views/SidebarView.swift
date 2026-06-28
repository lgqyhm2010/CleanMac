import CleanMacCore
import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarSection?
    @ObservedObject var store: CleaningStore
    var language: ResolvedLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            CleanMacPanel(padding: 12, tint: CleanMacTheme.accent) {
                HStack(spacing: 10) {
                    CleanMacFeatureImage(asset: .mascot, tint: CleanMacTheme.accent, isActive: selection == .scan)
                        .frame(width: 48, height: 48)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("CleanMac")
                            .font(.headline.weight(.bold))
                        Text(L10n.text(.cleaner, language: language))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(CleanMacTheme.secondaryText)
                            .lineLimit(1)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.top, 18)

            Text(L10n.text(.cleaner, language: language).uppercased())
                .font(.caption.weight(.bold))
                .foregroundStyle(CleanMacTheme.sidebarText)
                .padding(.horizontal, 20)

            VStack(spacing: 8) {
                sidebarRow(.scan, detail: L10n.folderCount(store.roots.count, language: language))
                sidebarRow(.uninstaller, detail: L10n.uninstallPlanCount(store.uninstallPlans.count, language: language))
                sidebarRow(.results, detail: L10n.candidateCount(store.candidates.count, language: language))
                sidebarRow(.aiReview, detail: L10n.selectedCount(store.selectedSummary.selectedCount, language: language))
            }
            .padding(.horizontal, 12)

            Spacer(minLength: 0)

            StatusBadge(
                text: L10n.status(store.status, language: language),
                symbolName: CleanMacTheme.statusSymbol(store.status),
                tint: CleanMacTheme.statusColor(store.status),
                isActive: store.isScanning || store.isCleaning || store.isReviewingWithAI
            )
            .padding(.horizontal, 14)
            .padding(.bottom, 16)
        }
        .frame(minWidth: 230, idealWidth: 250, maxWidth: 270, maxHeight: .infinity, alignment: .topLeading)
        .background(CleanMacTheme.sidebar)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(CleanMacTheme.ink)
                .frame(width: 2)
        }
        .navigationSplitViewColumnWidth(min: 230, ideal: 250)
    }

    private func sidebarRow(_ section: SidebarSection, detail: String) -> some View {
        let tint = CleanMacTheme.sectionTint(section)
        let isSelected = selection == section

        return Button {
            selection = section
        } label: {
            HStack(spacing: 10) {
                CleanMacFeatureImage(asset: section.illustrationAsset, tint: tint, isActive: isSelected)
                    .frame(width: 38, height: 38)

                VStack(alignment: .leading, spacing: 2) {
                    Text(section.title(language: language))
                        .font(.callout.weight(isSelected ? .bold : .semibold))
                        .foregroundStyle(CleanMacTheme.ink)
                        .lineLimit(1)
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(CleanMacTheme.secondaryText)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isSelected ? CleanMacTheme.paper : Color.clear, in: CleanMacTheme.panelShape)
            .overlay {
                CleanMacTheme.panelShape
                    .strokeBorder(isSelected ? CleanMacTheme.ink : Color.clear, lineWidth: 2)
            }
            .shadow(color: isSelected ? CleanMacTheme.shadow : .clear, radius: 0, x: 0, y: 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
