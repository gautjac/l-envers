import SwiftUI

/// The holes panel: the structural diagnoses, in oxblood. Clicking a hole
/// lights up its implicated units on the spine and jumps the source pane to
/// the first one. Also surfaces the repeat clusters as a compact summary.
struct HolesPanel: View {
    @EnvironmentObject private var workbench: Workbench

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "stethoscope").foregroundStyle(Theme.oxblood)
                Text(t("Les trous", "The Holes"))
                    .font(Theme.serif(14, .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                Text("\(workbench.holes.count)")
                    .font(Theme.mono(11, .bold))
                    .foregroundStyle(Theme.oxblood)
                    .padding(.horizontal, 7).padding(.vertical, 2)
                    .background(Theme.oxbloodWash, in: Capsule())
            }
            .padding(.horizontal, 14).padding(.vertical, 11)
            .background(Theme.paperRaised)

            Divider().overlay(Theme.paperEdge)

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    if workbench.holes.isEmpty {
                        soundStructure
                    } else {
                        ForEach(workbench.holes) { hole in
                            holeRow(hole)
                        }
                    }

                    if !repeatSummary.isEmpty {
                        Divider().overlay(Theme.paperEdge).padding(.vertical, 4)
                        repeatSummaryView
                    }
                }
                .padding(14)
            }
        }
        .background(Theme.paper)
    }

    private var soundStructure: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(t("Structure saine", "Sound structure"), systemImage: "checkmark.seal")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(red: 0.255, green: 0.522, blue: 0.420))
            Text(t("La radiographie ne révèle aucun trou de structure flagrant. Le tracé de tension reste le juge.",
                   "The X-ray reveals no glaring structural holes. The tension EKG remains the judge."))
                .font(.system(size: 11))
                .foregroundStyle(Theme.inkDim)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func holeRow(_ hole: StructuralHole) -> some View {
        let selected = workbench.selectedHole == hole.id
        return Button {
            workbench.selectHole(hole)
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "circle.fill")
                        .font(.system(size: 6))
                        .foregroundStyle(Theme.oxblood)
                        .padding(.top, 5)
                    Text(hole.title)
                        .font(Theme.serif(13, .semibold))
                        .foregroundStyle(Theme.ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(hole.detail)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.inkDim)
                    .fixedSize(horizontal: false, vertical: true)
                if !hole.unitIndices.isEmpty {
                    Text(t("unités ", "units ") + hole.unitIndices.map { String($0 + 1) }.joined(separator: ", "))
                        .font(Theme.mono(9, .medium))
                        .foregroundStyle(Theme.oxbloodDim)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(10)
            .background(selected ? Theme.oxbloodWash : Theme.paperRaised.opacity(0.6),
                        in: RoundedRectangle(cornerRadius: 7))
            .overlay(RoundedRectangle(cornerRadius: 7)
                .stroke(selected ? Theme.oxblood : Theme.paperEdge, lineWidth: selected ? 1.4 : 0.8))
        }
        .buttonStyle(.plain)
    }

    // Repeat clusters surfaced from the local analysis.
    private var repeatSummary: [SkeletonAnalysis.RepeatCluster] {
        SkeletonAnalysis.repeatClusters(in: workbench.units)
    }

    private var repeatSummaryView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(t("Travail répété", "Repeated work"), systemImage: "repeat")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Theme.ochre)
            ForEach(Array(repeatSummary.enumerated()), id: \.offset) { idx, cluster in
                HStack(alignment: .top, spacing: 6) {
                    Text("#\(idx + 1)")
                        .font(Theme.mono(10, .bold))
                        .foregroundStyle(Theme.ochre)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(t("unités ", "units ") + cluster.positions.map { String($0 + 1) }.joined(separator: ", "))
                            .font(Theme.mono(10))
                            .foregroundStyle(Theme.inkDim)
                        Text(t("font le même travail", "do the same job"))
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.inkFaint)
                    }
                }
            }
        }
    }
}
