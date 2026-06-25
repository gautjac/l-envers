import SwiftUI

/// L'Envers's visual identity: an architect's drafting table. Ink on bone-white
/// paper, a blueprint-blue spine running down the page, oxblood red reserved for
/// the things that hurt — flatlines and structural holes. Serif (New York) for
/// labels and headings, monospace for the source text. Calm, precise, drafting-table.
///
/// Distinct from L'Équerre (which is dark indigo graph-paper): L'Envers is a
/// *light* surface — a sheet of vellum on a table, not a backlit blueprint.
enum Theme {
    // MARK: Paper

    /// Bone-white drafting paper.
    static let paper       = Color(red: 0.965, green: 0.957, blue: 0.933)   // #F6F4EE
    static let paperRaised = Color(red: 0.988, green: 0.984, blue: 0.969)   // #FCFBF7
    static let paperSunken = Color(red: 0.925, green: 0.914, blue: 0.882)   // #ECE9E1
    static let paperEdge   = Color(red: 0.831, green: 0.812, blue: 0.769)   // #D4CFC4

    // MARK: Ink

    /// Near-black drafting ink and its softer weights.
    static let ink         = Color(red: 0.114, green: 0.118, blue: 0.122)   // #1D1E1F
    static let inkDim       = Color(red: 0.357, green: 0.369, blue: 0.376)  // #5B5E60
    static let inkFaint     = Color(red: 0.561, green: 0.573, blue: 0.580)  // #8F9294

    // MARK: Blueprint blue — the spine

    static let blueprint    = Color(red: 0.180, green: 0.455, blue: 0.706)  // #2E74B4
    static let blueprintDim  = Color(red: 0.180, green: 0.455, blue: 0.706).opacity(0.55)
    static let blueprintFaint = Color(red: 0.180, green: 0.455, blue: 0.706).opacity(0.16)

    // MARK: Oxblood — reserved for pain (flatlines, holes)

    static let oxblood      = Color(red: 0.557, green: 0.157, blue: 0.157)  // #8E2828
    static let oxbloodDim    = Color(red: 0.557, green: 0.157, blue: 0.157).opacity(0.50)
    static let oxbloodWash    = Color(red: 0.557, green: 0.157, blue: 0.157).opacity(0.10)

    /// A warm ochre used to flag repeated work — scenes doing the same job.
    static let ochre        = Color(red: 0.690, green: 0.494, blue: 0.169)  // #B07E2B
    static let ochreWash     = Color(red: 0.690, green: 0.494, blue: 0.169).opacity(0.14)

    // MARK: Type

    /// The serif drafting face — New York if present, falling back gracefully.
    static func serif(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }
    /// Monospace for source text and indices.
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }
}

/// A faint grid drawn behind drafting surfaces, like graph paper on a table.
/// Respects reduced motion implicitly (it's static) and stays whisper-quiet.
struct DraftingGrid: View {
    var cell: CGFloat = 22
    var body: some View {
        Canvas { ctx, size in
            var minor = Path()
            var x: CGFloat = 0
            while x <= size.width { minor.move(to: CGPoint(x: x, y: 0)); minor.addLine(to: CGPoint(x: x, y: size.height)); x += cell }
            var y: CGFloat = 0
            while y <= size.height { minor.move(to: CGPoint(x: 0, y: y)); minor.addLine(to: CGPoint(x: size.width, y: y)); y += cell }
            ctx.stroke(minor, with: .color(Theme.blueprint.opacity(0.05)), lineWidth: 0.5)
        }
        .allowsHitTesting(false)
    }
}
