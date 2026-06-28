import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarSection?
    @ObservedObject var store: CleaningStore

    var body: some View {
        List(selection: $selection) {
            Section("Cleaner") {
                sidebarRow(.scan, detail: "\(store.roots.count) folders")
                sidebarRow(.results, detail: "\(store.candidates.count) candidates")
                sidebarRow(.aiReview, detail: "\(store.selectedSummary.selectedCount) selected")
            }
        }
        .listStyle(.sidebar)
        .navigationSplitViewColumnWidth(min: 190, ideal: 220)
    }

    private func sidebarRow(_ section: SidebarSection, detail: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: section.symbolName)
                .foregroundStyle(.secondary)
                .frame(width: 16)
            VStack(alignment: .leading, spacing: 2) {
                Text(section.title)
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
