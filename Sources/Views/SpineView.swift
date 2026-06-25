import SwiftUI

/// The X-ray itself: the EKG up top, then the vertical spine of cards. A
/// continuous blueprint rail runs behind the cards, tying the vertebrae into
/// one column. Empty/analyzing/failed states live here too.
struct SpineView: View {
    @EnvironmentObject private var workbench: Workbench

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider().overlay(Theme.paperEdge)

            switch workbench.phase {
            case .idle where !workbench.hasRadiograph:
                emptyState
            case .analyzing:
                analyzingState
            case .failed(let message):
                failedState(message)
            default:
                spineContent
            }
        }
        .background(Theme.paper)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "waveform.path.ecg.rectangle").foregroundStyle(Theme.blueprint)
            Text(t("Le squelette", "The Skeleton"))
                .font(Theme.serif(14, .semibold))
                .foregroundStyle(Theme.ink)
            Spacer()
            if workbench.hasRadiograph {
                Text(t("\(workbench.units.count) unités", "\(workbench.units.count) units"))
                    .font(Theme.mono(10))
                    .foregroundStyle(Theme.inkFaint)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, 11)
        .background(Theme.paperRaised)
    }

    // MARK: States

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "skew")
                .font(.system(size: 40, weight: .ultraLight))
                .foregroundStyle(Theme.blueprintDim)
            Text(t("Pas encore de radiographie.", "No X-ray yet."))
                .font(Theme.serif(15))
                .foregroundStyle(Theme.inkDim)
            Text(t("Colle un texte à gauche, puis Radiographier.",
                   "Paste a text on the left, then X-ray."))
                .font(.system(size: 12))
                .foregroundStyle(Theme.inkFaint)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var analyzingState: some View {
        VStack(spacing: 14) {
            Spacer()
            ProgressView().controlSize(.large).tint(Theme.blueprint)
            Text(t("Radiographie en cours…", "X-raying…"))
                .font(Theme.serif(15))
                .foregroundStyle(Theme.inkDim)
            Text(t("Claude lit pour la structure, pas pour le sens.",
                   "Claude reads for structure, not meaning."))
                .font(.system(size: 11))
                .foregroundStyle(Theme.inkFaint)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func failedState(_ message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 32))
                .foregroundStyle(Theme.ochre)
            Text(message)
                .font(.system(size: 13))
                .foregroundStyle(Theme.inkDim)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)
            Button {
                Task { await workbench.radiograph() }
            } label: {
                Label(t("Réessayer", "Retry"), systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Spine

    private var spineContent: some View {
        let flat = workbench.flatlineIndices
        let repeated = workbench.repeatedIndices
        let tags = workbench.clusterTags
        let holeUnits = workbench.highlightedUnitsFromHole

        return ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    if !workbench.units.isEmpty {
                        TensionEKG(units: workbench.units,
                                   flatlines: workbench.flatlines,
                                   focused: workbench.focusedUnit) { i in
                            workbench.focus(unitAt: i)
                            withAnimation(.easeInOut(duration: 0.25)) { proxy.scrollTo(i, anchor: .center) }
                        }
                        .padding(.bottom, 4)
                    }

                    ZStack(alignment: .leading) {
                        // The continuous spine rail behind the cards.
                        Rectangle()
                            .fill(Theme.blueprintFaint)
                            .frame(width: 2)
                            .padding(.leading, 25)

                        VStack(spacing: 10) {
                            ForEach(workbench.units) { unit in
                                let pos = unit.index
                                SpineCard(position: pos,
                                          unit: unit,
                                          isFocused: workbench.focusedUnit == pos,
                                          isFlatlined: flat.contains(pos),
                                          isRepeated: repeated.contains(pos),
                                          clusterTag: tags[pos],
                                          isHoleHighlighted: holeUnits.contains(pos)) {
                                    workbench.focus(unitAt: pos)
                                }
                                .id(pos)
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
    }
}
