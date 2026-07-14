import CleanMacCore
import SwiftUI

struct SidebarView: View {
    @Binding var selection: SidebarSection
    let store: CleaningStore
    var language: ResolvedLanguage

    @State private var hoveredSection: SidebarSection?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                CleanMacFeatureImage(asset: .mascot, tint: CleanMacTheme.accent, isActive: false)
                    .frame(width: 42, height: 42)

                VStack(alignment: .leading, spacing: 2) {
                    Text("CleanMac")
                        .font(.callout.weight(.bold))
                        .foregroundStyle(CleanMacTheme.sidebarPrimaryText)
                    Text(L10n.text(.appTagline, language: language))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(CleanMacTheme.sidebarText)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(CleanMacTheme.sidebarDivider)
                    .frame(height: 1)
            }

            ScrollView {
                VStack(alignment: .leading, spacing: 3) {
                    sidebarSection(.diskOverview)
                    sidebarRow(.diskOverview, value: sidebarValue(for: .diskOverview))
                    sidebarRow(.speedUp, value: sidebarValue(for: .speedUp))
                    sidebarRow(.cleanUp, value: sidebarValue(for: .cleanUp))
                    sidebarRow(.manageSpace, value: sidebarValue(for: .manageSpace))

                    sidebarSection(.duplicates)
                        .padding(.top, 8)
                    sidebarRow(.duplicates, value: sidebarValue(for: .duplicates))
                    sidebarRow(.uninstaller, value: sidebarValue(for: .uninstaller))
                    sidebarRow(.analyzeSpace, value: sidebarValue(for: .analyzeSpace))

                    sidebarSection(.aiReview)
                        .padding(.top, 8)
                    sidebarRow(.aiReview, value: sidebarValue(for: .aiReview))

                    sidebarSection(.settings)
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
                .fill(CleanMacTheme.sidebarBorder)
                .frame(width: 2)
        }
        .onChange(of: selection) { _, _ in
            hoveredSection = nil
        }
    }

    private func sidebarSection(_ section: SidebarSection) -> some View {
        Text(section.groupTitle(language: language).uppercased())
            .font(.system(size: 9, weight: .bold))
            .tracking(0.8)
            .foregroundStyle(CleanMacTheme.sidebarText)
            .padding(.horizontal, 8)
            .padding(.bottom, 4)
    }

    private func sidebarRow(_ section: SidebarSection, value: String) -> some View {
        let tint = CleanMacTheme.sectionTint(section)
        let isSelected = selection == section
        let isHovered = hoveredSection == section
        let shouldAnimateIcon = isHovered && !isSelected

        return Button {
            hoveredSection = nil
            selection = section
        } label: {
            HStack(spacing: 10) {
                CleanMacFeatureImage(asset: section.illustrationAsset, tint: tint, isActive: shouldAnimateIcon)
                    .frame(width: 38, height: 38)

                VStack(alignment: .leading, spacing: 2) {
                    Text(section.title(language: language))
                        .font(.callout.weight(isSelected ? .bold : .semibold))
                        .foregroundStyle(CleanMacTheme.sidebarRowText)
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
                        .foregroundStyle(isSelected ? CleanMacTheme.ink : tint)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                isSelected
                    ? CleanMacTheme.sidebarSelectedFill
                    : (isHovered ? tint.opacity(0.10) : Color.clear),
                in: CleanMacTheme.panelShape
            )
            .overlay {
                CleanMacTheme.panelShape
                    .strokeBorder(
                        isSelected ? CleanMacTheme.ink : (isHovered ? tint.opacity(0.72) : CleanMacTheme.sidebarDivider),
                        lineWidth: isSelected ? 2 : 1
                    )
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { isHovering in
            updateHover(isHovering, section: section)
        }
    }

    private func updateHover(_ isHovering: Bool, section: SidebarSection) {
        if isHovering {
            hoveredSection = section
        } else if hoveredSection == section {
            hoveredSection = nil
        }
    }

    private func sidebarValue(for section: SidebarSection) -> String {
        switch section {
        case .diskOverview:
            return store.volumeSnapshot.map { Formatters.bytes($0.usedCapacityBytes) } ?? ""
        case .speedUp:
            if store.isScanning {
                return L10n.text(.scanning, language: language)
            }
            return formattedBytes(cleanupBytes(for: [.cache, .logs, .temporary, .developer]))
        case .cleanUp:
            return formattedBytes(store.lastReport?.totalBytes ?? 0)
        case .manageSpace:
            return formattedBytes(store.selectedSummary.totalBytes)
        case .duplicates:
            return formattedBytes(store.duplicateReclaimableBytes)
        case .uninstaller:
            return formattedBytes(store.uninstallReclaimableBytes)
        case .analyzeSpace:
            return store.candidates.isEmpty ? "" : "\(store.candidates.count)"
        case .aiReview:
            return store.isReviewingWithAI
                ? L10n.text(.reviewing, language: language)
                : L10n.status(store.status, language: language)
        case .settings:
            return ""
        }
    }

    private func cleanupBytes(for categories: Set<CandidateCategory>) -> Int64 {
        store.candidates
            .filter { categories.contains($0.category) }
            .reduce(0) { $0 + $1.sizeBytes }
    }

    private func formattedBytes(_ bytes: Int64) -> String {
        bytes > 0 ? Formatters.bytes(bytes) : ""
    }
}
