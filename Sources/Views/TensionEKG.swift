import SwiftUI

/// The tension EKG: a horizontal sparkline of every unit's tension, with
/// FLATLINE stretches shaded in oxblood — the dramatically dead zones. Clicking
/// a sample focuses that unit. The focused unit gets a blueprint marker.
struct TensionEKG: View {
    let units: [StoryUnit]
    let flatlines: [SkeletonAnalysis.Flatline]
    let focused: Int?
    let onTap: (Int) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "waveform.path.ecg").foregroundStyle(Theme.blueprint)
                Text(t("Le tracé de tension", "Tension EKG"))
                    .font(Theme.serif(13, .semibold))
                    .foregroundStyle(Theme.ink)
                Spacer()
                if !flatlines.isEmpty {
                    Label(t("\(flatlines.count) zone(s) plate(s)", "\(flatlines.count) flat zone(s)"),
                          systemImage: "exclamationmark.triangle.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Theme.oxblood)
                }
            }

            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let n = units.count
                ZStack {
                    // Baseline grid.
                    Path { p in
                        for frac in [0.0, 0.5, 1.0] {
                            let y = h - h * frac
                            p.move(to: CGPoint(x: 0, y: y))
                            p.addLine(to: CGPoint(x: w, y: y))
                        }
                    }
                    .stroke(Theme.blueprintFaint, lineWidth: 0.5)

                    // Flatline shading.
                    ForEach(Array(flatlines.enumerated()), id: \.offset) { _, fl in
                        let x0 = xPos(fl.range.lowerBound, n: n, w: w)
                        let x1 = xPos(fl.range.upperBound, n: n, w: w)
                        Rectangle()
                            .fill(Theme.oxbloodWash)
                            .frame(width: max(2, x1 - x0))
                            .position(x: (x0 + x1) / 2, y: h / 2)
                    }

                    if n >= 2 {
                        // Area under the curve.
                        ekgArea(w: w, h: h, n: n)
                            .fill(LinearGradient(colors: [Theme.blueprint.opacity(0.18), .clear],
                                                 startPoint: .top, endPoint: .bottom))
                        // The line.
                        ekgLine(w: w, h: h, n: n)
                            .stroke(Theme.blueprint, style: StrokeStyle(lineWidth: 1.6, lineJoin: .round))
                    }

                    // Sample dots (tappable).
                    ForEach(units.indices, id: \.self) { i in
                        let x = xPos(i, n: n, w: w)
                        let y = h - h * CGFloat(units[i].tension)
                        Circle()
                            .fill(focused == i ? Theme.blueprint : Theme.paper)
                            .overlay(Circle().stroke(focused == i ? Theme.blueprint : Theme.blueprintDim,
                                                     lineWidth: 1.4))
                            .frame(width: focused == i ? 11 : 7, height: focused == i ? 11 : 7)
                            .position(x: x, y: y)
                            .onTapGesture { onTap(i) }
                            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: focused)
                    }
                }
            }
            .frame(height: 84)
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .background(Theme.paperRaised, in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.paperEdge, lineWidth: 0.8))
        }
    }

    private func xPos(_ i: Int, n: Int, w: CGFloat) -> CGFloat {
        guard n > 1 else { return w / 2 }
        let inset: CGFloat = 10
        let usable = w - inset * 2
        return inset + usable * CGFloat(i) / CGFloat(n - 1)
    }

    private func ekgLine(w: CGFloat, h: CGFloat, n: Int) -> Path {
        Path { p in
            for i in units.indices {
                let pt = CGPoint(x: xPos(i, n: n, w: w), y: h - h * CGFloat(units[i].tension))
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
        }
    }

    private func ekgArea(w: CGFloat, h: CGFloat, n: Int) -> Path {
        Path { p in
            p.move(to: CGPoint(x: xPos(0, n: n, w: w), y: h))
            for i in units.indices {
                p.addLine(to: CGPoint(x: xPos(i, n: n, w: w), y: h - h * CGFloat(units[i].tension)))
            }
            p.addLine(to: CGPoint(x: xPos(n - 1, n: n, w: w), y: h))
            p.closeSubpath()
        }
    }
}
