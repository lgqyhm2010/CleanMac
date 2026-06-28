import CleanMacCore
import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarSection?
    @ObservedObject var store: CleaningStore
    var language: ResolvedLanguage

    var body: some View {
        List(selection: $selection) {
            Section(L10n.text(.cleaner, language: language)) {
                sidebarRow(.scan, detail: L10n.folderCount(store.roots.count, language: language))
                sidebarRow(.uninstaller, detail: L10n.uninstallPlanCount(store.uninstallPlans.count, language: language))
                sidebarRow(.results, detail: L10n.candidateCount(store.candidates.count, language: language))
                sidebarRow(.aiReview, detail: L10n.selectedCount(store.selectedSummary.selectedCount, language: language))
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 190, ideal: 220)
    }

    private func sidebarRow(_ section: SidebarSection, detail: String) -> some View {
        let tint = CleanMacTheme.sectionTint(section)
        return HStack(spacing: 10) {
            Image(systemName: section.symbolName)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tint)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text(section.title(language: language))
                    .fontWeight(selection == section ? .semibold : .regular)
                    .lineLimit(1)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .tag(section)
    }
}
