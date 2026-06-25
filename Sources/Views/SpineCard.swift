import SwiftUI

/// One vertebra of the spine: a card showing what a unit DOES. Label (serif),
/// function verb (the headline), a type chip, a tension bar, and structural
/// markers — a repeat-cluster tag and a flatline/oxblood wash when implicated.
struct SpineCard: View {
    let position: Int
    let unit: StoryUnit
    let isFocused: Bool
    let isFlatlined: Bool
    let isRepeated: Bool
    let clusterTag: Int?
    let isHoleHighlighted: Bool
    let onTap: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var accent: Color { unit.type.color }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                // Index gutter + the spine rail dot.
                VStack(spacing: 4) {
                    Text(String(format: "%02d", position + 1))
                        .font(Theme.mono(11, .medium))
                        .foregroundStyle(Theme.inkFaint)
                    Circle()
                        .fill(accent)
                        .frame(width: 8, height: 8)
                        .overlay(Circle().stroke(Theme.paper, lineWidth: 1.5))
                }
                .frame(width: 26)

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(unit.label.isEmpty ? t("(sans nom)", "(unnamed)") : unit.label)
                            .font(Theme.serif(15, .semibold))
                            .foregroundStyle(Theme.ink)
                            .lineLimit(1)
                        Spacer(minLength: 4)
                        typeChip
                    }

                    // The function verb — the headline of the X-ray.
                    Text(unit.function)
                        .font(Theme.serif(13))
                        .italic()
                        .foregroundStyle(Theme.inkDim)
                        .fixedSize(horizontal: false, vertical: true)

                    if let note = unit.note, !note.isEmpty {
                        Text(note)
                            .font(.system(size: 11))
                            .foregroundStyle(Theme.inkFaint)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(spacing: 8) {
                        tensionBar
                        if isRepeated, let tag = clusterTag {
                            repeatTag(tag)
                        }
                        if isFlatlined {
                            Label(t("plat", "flat"), systemImage: "minus")
                                .labelStyle(.titleAndIcon)
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundStyle(Theme.oxblood)
                        }
                    }
                }
            }
            .padding(12)
            .background(cardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(borderColor, lineWidth: isFocused ? 1.6 : 0.8)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: isFocused)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: isHoleHighlighted)
    }

    private var cardBackground: some View {
        ZStack {
            if isFlatlined {
                Theme.oxbloodWash
            } else if isRepeated {
                Theme.ochreWash
            } else {
                isFocused ? Theme.paperRaised : Theme.paperRaised.opacity(0.6)
            }
        }
    }

    private var borderColor: Color {
        if isFocused { return Theme.blueprint }
        if isHoleHighlighted { return Theme.oxblood }
        if isFlatlined { return Theme.oxbloodDim }
        if isRepeated { return Theme.ochre.opacity(0.6) }
        return Theme.paperEdge
    }

    private var typeChip: some View {
        HStack(spacing: 4) {
            Image(systemName: unit.type.symbol).font(.system(size: 8, weight: .bold))
            Text(unit.type.label).font(.system(size: 9, weight: .semibold))
        }
        .foregroundStyle(accent)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(accent.opacity(0.12), in: Capsule())
    }

    private var tensionBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.paperSunken)
                Capsule()
                    .fill(isFlatlined ? Theme.oxblood : Theme.blueprint)
                    .frame(width: max(3, geo.size.width * unit.tension))
            }
        }
        .frame(height: 5)
        .frame(maxWidth: 120)
        .accessibilityLabel(t("tension", "tension"))
        .accessibilityValue("\(Int(unit.tension * 100))%")
    }

    private func repeatTag(_ tag: Int) -> some View {
        HStack(spacing: 3) {
            Image(systemName: "repeat").font(.system(size: 8, weight: .bold))
            Text("#\(tag + 1)").font(Theme.mono(9, .bold))
        }
        .foregroundStyle(Theme.ochre)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(Theme.ochre.opacity(0.14), in: Capsule())
    }
}
