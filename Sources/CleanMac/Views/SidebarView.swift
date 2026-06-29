import CleanMacCore
import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarSection?
    @ObservedObject var store: CleaningStore
    var language: ResolvedLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                CleanMacFeatureImage(asset: .mascot, tint: CleanMacTheme.accent, isActive: selection == .diskOverview)
                    .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 2) {
                    Text("CleanMac")
                        .font(.callout.weight(.bold))
                        .foregroundStyle(CleanMacTheme.sidebarPrimaryText)
                    Text("Keep it sparkly")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(CleanMacTheme.sidebarText)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(CleanMacTheme.sidebarBorder)
                    .frame(height: 2)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 3) {
                    sidebarSection("Overview")
                    sidebarRow(.diskOverview, value: store.lastReport == nil ? "500 GB" : Formatters.bytes(store.lastReport?.totalBytes ?? 0))
                    sidebarRow(.speedUp, value: store.isScanning ? L10n.text(.scanning, language: language) : "5.1 GB")
                    sidebarRow(.cleanUp, value: store.lastReport == nil ? "32 GB" : Formatters.bytes(store.lastReport?.totalBytes ?? 0))
                    sidebarRow(.manageSpace, value: store.selectedSummary.totalBytes == 0 ? "20 GB" : Formatters.bytes(store.selectedSummary.totalBytes))

                    sidebarSection("Pro tools")
                        .padding(.top, 8)
                    sidebarRow(.duplicates, value: store.duplicateReclaimableBytes == 0 ? "10.2 GB" : Formatters.bytes(store.duplicateReclaimableBytes))
                    sidebarRow(.uninstaller, value: store.uninstallReclaimableBytes == 0 ? "15 GB" : Formatters.bytes(store.uninstallReclaimableBytes))
                    sidebarRow(.analyzeSpace, value: store.candidates.isEmpty ? "6.4 GB" : "\(store.candidates.count)")

                    sidebarSection("AI - Local")
                        .padding(.top, 8)
                    sidebarRow(.aiReview, value: store.isReviewingWithAI ? L10n.text(.reviewing, language: language) : "NEW")

                    sidebarSection("System")
                        .padding(.top, 8)
                    sidebarRow(.settings, value: "")
                }
                .padding(8)
            }

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
        .frame(width: 222)
        .frame(maxHeight: .infinity, alignment: .topLeading)
        .background(CleanMacTheme.sidebar)
        .overlay(alignment: .trailing) {
            Rectangle()
                .fill(CleanMacTheme.ink)
                .frame(width: 3)
        }
    }

    private func sidebarSection(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.system(size: 9, weight: .bold))
            .tracking(0.8)
            .foregroundStyle(CleanMacTheme.sidebarText)
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
    }

    private func sidebarRow(_ section: SidebarSection, value: String) -> some View {
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
                        .foregroundStyle(isSelected ? Color.white : CleanMacTheme.sidebarRowText)
                        .lineLimit(1)
                    Text(section.subtitle(language: language))
                        .font(.caption)
                        .foregroundStyle(CleanMacTheme.sidebarText)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                if !value.isEmpty {
                    Text(value)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(tint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(isSelected ? Color.white.opacity(0.12) : Color.clear, in: CleanMacTheme.panelShape)
            .overlay {
                CleanMacTheme.panelShape
                    .strokeBorder(isSelected ? tint : Color.clear, lineWidth: 2)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
