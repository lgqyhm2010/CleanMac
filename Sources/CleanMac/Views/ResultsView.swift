import CleanMacCore
import SwiftUI

struct ResultsView: View {
    let store: CleaningStore
    var language: ResolvedLanguage
    @State private var confirmTrash = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            CleanMacPageBackground(accent: CleanMacTheme.sectionTint(.cleanUp))

            VStack(spacing: 14) {
                CleanMacPanel(padding: 14, tint: CleanMacTheme.sectionTint(.cleanUp)) {
                    resultsHeader
                }

                CleanMacPanel(padding: 0, tint: CleanMacTheme.sectionTint(.cleanUp)) {
                    resultsTableContent
                }
                .frame(minHeight: 280, maxHeight: .infinity)

                CleanMacPanel(padding: 14, tint: CleanMacTheme.sectionTint(.cleanUp)) {
                    CandidateDetailView(
                        candidate: store.selectedCandidate,
                        duplicateGroup: store.duplicateGroup(containing: store.selectedCandidate),
                        uninstallPlan: store.uninstallPlan(containing: store.selectedCandidate),
                        language: language
                    )
                    .id(store.selectedCandidate?.id ?? "empty")
                    .transition(.opacity)
                }
            }
            .padding(16)
        }
        .foregroundStyle(CleanMacTheme.ink)
        .animation(CleanMacMotion.allowed(reduceMotion, CleanMacMotion.quick), value: store.candidates.count)
        .animation(CleanMacMotion.allowed(reduceMotion, CleanMacMotion.quick), value: store.selectedCandidateID)
        .alert(L10n.text(.moveSelectedItemsToTrash, language: language), isPresented: $confirmTrash) {
            Button(L10n.text(.cancel, language: language), role: .cancel) {}
            Button(L10n.text(.moveToTrash, language: language), role: .destructive) {
                store.cleanSelected()
            }
        } message: {
            Text(L10n.moveToTrashSummary(
                selectedCount: store.selectedSummary.selectedCount,
                protectedCount: store.selectedProtectedCandidates.count,
                totalBytes: store.selectedSummary.totalBytes,
                language: language
            ))
        }
    }

    @ViewBuilder
    private var resultsTableContent: some View {
        if store.candidates.isEmpty {
            if store.isScanning {
                CleanMacProgressState(
                    title: L10n.text(.scanning, language: language),
                    symbolName: "magnifyingglass",
                    asset: .diskOverview,
                    tint: CleanMacTheme.accent
                )
            } else {
                CleanMacEmptyState(
                    title: L10n.text(.noCandidates, language: language),
                    symbolName: "checkmark.seal",
                    asset: .cleanupTrash,
                    tint: CleanMacTheme.mint
                )
            }
        } else {
            CandidatePaperTable(store: store, language: language)
        }
    }

    private var resultsHeader: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                CleanMacFeatureImage(
                    asset: .cleanupTrash,
                    tint: CleanMacTheme.sectionTint(.cleanUp),
                    isActive: store.isCleaning || store.isScanning
                )
                .frame(width: 48, height: 48)

                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.candidatesHeadline(store.candidates.count, language: language))
                        .font(.headline)
                    Text(selectedDetailText)
                        .font(.caption)
                        .foregroundStyle(CleanMacTheme.secondaryText)
                }

                Spacer()

                StatusBadge(
                    text: L10n.status(store.status, language: language),
                    symbolName: CleanMacTheme.statusSymbol(store.status),
                    tint: CleanMacTheme.statusColor(store.status),
                    isActive: store.isCleaning || store.isScanning
                )
            }

            HStack(spacing: 10) {
                Spacer(minLength: 0)

                Button {
                    store.selectAll()
                } label: {
                    Label(L10n.text(.selectAll, language: language), systemImage: "checklist.checked")
                }
                .disabled(store.candidates.isEmpty)

                Button {
                    store.selectDuplicateCopies()
                } label: {
                    Label(L10n.text(.selectDuplicateCopies, language: language), systemImage: "doc.on.doc")
                }
                .disabled(store.movableDuplicateCandidates.isEmpty)

                Button {
                    store.clearSelection()
                } label: {
                    Label(L10n.text(.clear, language: language), systemImage: "xmark.circle")
                }
                .disabled(store.selectedSummary.selectedCount == 0)

                Button(role: .destructive) {
                    confirmTrash = true
                } label: {
                    Label(
                        store.isCleaning ? L10n.text(.moving, language: language) : L10n.text(.moveToTrash, language: language),
                        systemImage: "trash"
                    )
                }
                .buttonStyle(CleanMacRaisedButtonStyle(tint: CleanMacTheme.danger, prominent: true))
                .disabled(store.selectedMovableCandidates.isEmpty || store.isBusy)
            }
        }
    }

    private var selectedDetailText: String {
        let base = "\(Formatters.bytes(store.selectedSummary.totalBytes)) \(L10n.text(.selected, language: language).lowercased())"
        let protectedCount = store.selectedProtectedCandidates.count
        guard protectedCount > 0 else { return base }
        return "\(base) · \(L10n.protectedItemCount(protectedCount, language: language))"
    }

}

private enum CandidateTableLayout {
    static let checkboxWidth: CGFloat = 54
    static let minimumNameWidth: CGFloat = 250
    static let categoryWidth: CGFloat = 132
    static let riskWidth: CGFloat = 166
    static let protectionWidth: CGFloat = 182
    static let sizeWidth: CGFloat = 136
    static let minimumWidth: CGFloat = checkboxWidth + minimumNameWidth + categoryWidth + riskWidth + protectionWidth + sizeWidth
}

private struct CandidatePaperTable: View {
    let store: CleaningStore
    var language: ResolvedLanguage

    var body: some View {
        GeometryReader { proxy in
            let tableWidth = max(proxy.size.width, CandidateTableLayout.minimumWidth)

            ScrollView(.horizontal) {
                VStack(spacing: 0) {
                    CandidateTableHeader(language: language)
                        .frame(width: tableWidth)

                    Rectangle()
                        .fill(CleanMacTheme.sidebarDivider)
                        .frame(height: 1)

                    ScrollView {
                        LazyVStack(spacing: 8) {
                            // Identity must follow the candidate, not its position:
                            // mid-list removals otherwise animate the wrong rows and
                            // leak per-row hover state onto whatever slides up.
                            ForEach(Array(store.candidates.enumerated()), id: \.element.id) { index, candidate in
                                CandidatePaperRow(
                                    candidate: candidate,
                                    isAlternate: index.isMultiple(of: 2),
                                    isFocused: store.selectedCandidateID == candidate.id,
                                    isSelectedForCleanup: store.selection.contains(candidate),
                                    language: language,
                                    toggleSelection: {
                                        store.toggle(candidate, selected: !store.selection.contains(candidate))
                                    },
                                    focusCandidate: {
                                        store.selectedCandidateID = candidate.id
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                    }
                    .background(CleanMacTheme.paper)
                }
                .frame(width: tableWidth, height: proxy.size.height, alignment: .top)
            }
            .scrollContentBackground(.hidden)
            .background(CleanMacTheme.paper)
            .clipShape(CleanMacTheme.panelShape)
            .environment(\.colorScheme, .light)
        }
    }
}

private struct CandidateTableHeader: View {
    var language: ResolvedLanguage

    var body: some View {
        HStack(spacing: 0) {
            Text("")
                .frame(width: CandidateTableLayout.checkboxWidth)

            CandidateHeaderText(L10n.text(.name, language: language))
                .frame(minWidth: CandidateTableLayout.minimumNameWidth, maxWidth: .infinity, alignment: .leading)

            CandidateColumnDivider()

            CandidateHeaderText(L10n.text(.category, language: language))
                .frame(width: CandidateTableLayout.categoryWidth, alignment: .leading)

            CandidateColumnDivider()

            CandidateHeaderText(L10n.text(.risk, language: language))
                .frame(width: CandidateTableLayout.riskWidth, alignment: .leading)

            CandidateColumnDivider()

            CandidateHeaderText(L10n.text(.protection, language: language))
                .frame(width: CandidateTableLayout.protectionWidth, alignment: .leading)

            CandidateColumnDivider()

            CandidateHeaderText(L10n.text(.size, language: language), alignment: .trailing)
                .frame(width: CandidateTableLayout.sizeWidth, alignment: .trailing)
        }
        .padding(.vertical, 12)
        .padding(.trailing, 10)
        .background {
            LinearGradient(
                colors: [
                    CleanMacTheme.paper,
                    CleanMacTheme.warmPane.opacity(0.92)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

private struct CandidateHeaderText: View {
    var title: String
    var alignment: Alignment

    init(_ title: String, alignment: Alignment = .leading) {
        self.title = title
        self.alignment = alignment
    }

    var body: some View {
        Text(title)
            .font(.caption.weight(.black))
            .foregroundStyle(CleanMacTheme.ink.opacity(0.86))
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: alignment)
            .padding(.horizontal, 14)
    }
}

private struct CandidateColumnDivider: View {
    var body: some View {
        Rectangle()
            .fill(CleanMacTheme.sidebarDivider.opacity(0.75))
            .frame(width: 1, height: 24)
    }
}

private struct CandidatePaperRow: View {
    var candidate: CleaningCandidate
    var isAlternate: Bool
    var isFocused: Bool
    var isSelectedForCleanup: Bool
    var language: ResolvedLanguage
    var toggleSelection: () -> Void
    var focusCandidate: () -> Void

    @State private var isHovered = false

    private var tint: Color {
        CleanMacTheme.categoryColor(candidate.category)
    }

    private var rowFill: Color {
        if isFocused {
            return CleanMacTheme.accent.opacity(0.16)
        }
        if isHovered {
            return CleanMacTheme.accent.opacity(0.08)
        }
        return isAlternate ? CleanMacTheme.warmPane.opacity(0.54) : CleanMacTheme.paper
    }

    var body: some View {
        HStack(spacing: 0) {
            CandidatePaperCheckbox(
                isSelected: isSelectedForCleanup,
                tint: CleanMacTheme.mint,
                language: language,
                action: toggleSelection
            )
            .frame(width: CandidateTableLayout.checkboxWidth)

            CandidateNameCell(candidate: candidate, tint: tint)
                .frame(minWidth: CandidateTableLayout.minimumNameWidth, maxWidth: .infinity, alignment: .leading)

            CandidateCategoryCell(candidate: candidate, language: language)
                .frame(width: CandidateTableLayout.categoryWidth, alignment: .leading)

            CandidateTableStatusPill(
                text: candidate.risk.displayName(language: language),
                symbolName: "exclamationmark.triangle",
                tint: CleanMacTheme.riskColor(candidate.risk)
            )
            .frame(width: CandidateTableLayout.riskWidth, alignment: .leading)

            CandidateTableStatusPill(
                text: candidate.protection.displayName(language: language),
                symbolName: candidate.protection.symbolName,
                tint: CleanMacTheme.protectionColor(candidate.protection)
            )
            .frame(width: CandidateTableLayout.protectionWidth, alignment: .leading)

            Text(Formatters.bytes(candidate.sizeBytes))
                .font(.callout.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(CleanMacTheme.ink)
                .lineLimit(1)
                .frame(width: CandidateTableLayout.sizeWidth, alignment: .trailing)
                .padding(.trailing, 16)
        }
        .frame(minHeight: 60)
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(rowFill)
        }
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 3, style: .continuous)
                .fill(isFocused ? CleanMacTheme.accent : .clear)
                .frame(width: 5)
                .padding(.vertical, 8)
        }
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(
                    isFocused ? CleanMacTheme.accent.opacity(0.74) : CleanMacTheme.sidebarDivider.opacity(0.36),
                    lineWidth: isFocused ? 1.5 : 1
                )
        }
        .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .onTapGesture(perform: focusCandidate)
        .onHover { isHovered = $0 }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(candidate.url.lastPathComponent)
        .accessibilityValue(Formatters.bytes(candidate.sizeBytes))
        .accessibilityAddTraits(isFocused ? [.isButton, .isSelected] : [.isButton])
        .accessibilityAction(.default, focusCandidate)
    }
}

private struct CandidatePaperCheckbox: View {
    var isSelected: Bool
    var tint: Color
    var language: ResolvedLanguage
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(isSelected ? tint.opacity(0.72) : CleanMacTheme.sidebarDivider.opacity(0.26))
                    .frame(width: 22, height: 22)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption.weight(.black))
                        .foregroundStyle(CleanMacTheme.ink)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .strokeBorder(
                        isSelected ? CleanMacTheme.ink.opacity(0.72) : CleanMacTheme.sidebarDivider.opacity(0.48),
                        lineWidth: 1.2
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.text(isSelected ? .deselectItem : .selectItem, language: language))
    }
}

private struct CandidateNameCell: View {
    var candidate: CleaningCandidate
    var tint: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: candidate.category.symbolName)
                .font(.system(size: 14, weight: .bold))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(tint)
                .frame(width: 30, height: 30)
                .background(tint.opacity(0.13), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(tint.opacity(0.38), lineWidth: 1)
                }

            VStack(alignment: .leading, spacing: 2) {
                Text(candidate.url.lastPathComponent)
                    .font(.callout.weight(.bold))
                    .foregroundStyle(CleanMacTheme.ink)
                    .lineLimit(1)

                Text(candidate.url.deletingLastPathComponent().path)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CleanMacTheme.secondaryText)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 6)
        .padding(.trailing, 12)
    }
}

private struct CandidateCategoryCell: View {
    var candidate: CleaningCandidate
    var language: ResolvedLanguage

    var body: some View {
        Text(candidate.category.displayName(language: language))
            .font(.callout.weight(.semibold))
            .foregroundStyle(CleanMacTheme.ink)
            .lineLimit(1)
            .padding(.horizontal, 14)
    }
}

private struct CandidateTableStatusPill: View {
    var text: String
    var symbolName: String
    var tint: Color

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: symbolName)
                .imageScale(.small)
            Text(text)
                .lineLimit(1)
                .minimumScaleFactor(0.78)
        }
        .font(.caption.weight(.bold))
        .foregroundStyle(CleanMacTheme.ink)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(tint.opacity(0.13), in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(tint.opacity(0.64), lineWidth: 1.2)
        }
        .padding(.horizontal, 12)
    }
}

private struct CandidateDetailView: View {
    var candidate: CleaningCandidate?
    var duplicateGroup: DuplicateFileGroup?
    var uninstallPlan: AppUninstallPlan?
    var language: ResolvedLanguage

    var body: some View {
        Group {
            if let candidate {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        CleanMacFeatureImage(
                            asset: .cleanupTrash,
                            tint: CleanMacTheme.riskColor(candidate.risk),
                            isActive: false
                        )
                        .frame(width: 38, height: 38)

                        Text(candidate.category.displayName(language: language))
                            .font(.headline)
                        Spacer()
                    Text(Formatters.bytes(candidate.sizeBytes))
                        .monospacedDigit()
                        .foregroundStyle(CleanMacTheme.secondaryText)
                    }

                    Text(candidate.url.path)
                        .font(.callout)
                        .textSelection(.enabled)
                        .lineLimit(2)

                    HStack(spacing: 18) {
                        StatusBadge(
                            text: candidate.risk.displayName(language: language),
                            symbolName: "exclamationmark.triangle",
                            tint: CleanMacTheme.riskColor(candidate.risk)
                        )
                        StatusBadge(
                            text: candidate.protection.displayName(language: language),
                            symbolName: candidate.protection.symbolName,
                            tint: CleanMacTheme.protectionColor(candidate.protection)
                        )
                        Label(Formatters.date(candidate.modifiedAt, language: language), systemImage: "calendar")
                    }
                    .font(.caption)
                    .foregroundStyle(CleanMacTheme.secondaryText)

                    if !candidate.reasons.isEmpty {
                        Text(candidate.reasons.map { L10n.scanReason($0, language: language) }.joined(separator: " · "))
                            .font(.caption)
                            .foregroundStyle(CleanMacTheme.secondaryText)
                    }

                    if !candidate.ruleMatches.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.text(.rules, language: language))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(CleanMacTheme.secondaryText)

                            ForEach(candidate.ruleMatches) { rule in
                                Label(L10n.safetyRule(rule, language: language), systemImage: "list.bullet.clipboard")
                                    .font(.caption)
                                    .foregroundStyle(CleanMacTheme.secondaryText)
                                    .lineLimit(2)
                            }
                        }
                    }

                    if let duplicateGroup {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.text(.duplicateGroup, language: language))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(CleanMacTheme.secondaryText)

                            Label(
                                L10n.duplicateGroupDetail(duplicateGroup, language: language),
                                systemImage: "doc.on.doc"
                            )
                            .font(.caption)
                            .foregroundStyle(CleanMacTheme.secondaryText)
                            .lineLimit(2)
                        }
                    }

                    if let uninstallPlan {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.text(.appUninstaller, language: language))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(CleanMacTheme.secondaryText)

                            Label(
                                L10n.appUninstallPlanDetail(uninstallPlan, language: language),
                                systemImage: "app.badge"
                            )
                            .font(.caption)
                            .foregroundStyle(CleanMacTheme.secondaryText)
                            .lineLimit(2)
                        }
                    }
                }
            } else {
                Text(L10n.text(.noItemSelected, language: language))
                    .foregroundStyle(CleanMacTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(minHeight: 110, alignment: .topLeading)
    }
}
