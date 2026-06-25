import SwiftUI

/// The dramatic / rhetorical *kind* of work a unit does. This is the spine's
/// colour code — each type reads at a glance. The raw values match the strict
/// enum the model is forced to return.
enum UnitType: String, Codable, CaseIterable, Identifiable {
    case setup       // lays groundwork, plants information
    case turn        // a reversal, a decision, a change of direction
    case reveal      // new information surfaces
    case reaction    // a character or argument absorbs what just happened
    case escalation  // raises the stakes / pressure
    case idle        // marks time, does nothing dramatically
    case repeatBeat  // does the same job as an earlier unit

    var id: String { rawValue }

    /// The model speaks JSON with `repeat`; Swift can't use that as a case name.
    /// Bridge the wire value here so the rest of the app uses `repeatBeat`.
    init(wire: String) {
        switch wire.lowercased() {
        case "repeat": self = .repeatBeat
        default: self = UnitType(rawValue: wire.lowercased()) ?? .idle
        }
    }

    /// Short FR label for the chip.
    var label: String {
        switch self {
        case .setup:      return t("mise en place", "setup")
        case .turn:       return t("retournement", "turn")
        case .reveal:     return t("révélation", "reveal")
        case .reaction:   return t("réaction", "reaction")
        case .escalation: return t("escalade", "escalation")
        case .idle:       return t("temps mort", "idle")
        case .repeatBeat: return t("redite", "repeat")
        }
    }

    /// The drafting colour for this kind of work.
    var color: Color {
        switch self {
        case .setup:      return Theme.inkDim
        case .turn:       return Theme.blueprint
        case .reveal:     return Color(red: 0.255, green: 0.522, blue: 0.420)
        case .reaction:   return Theme.inkFaint
        case .escalation: return Theme.ochre
        case .idle:       return Theme.inkFaint.opacity(0.7)
        case .repeatBeat: return Theme.oxblood
        }
    }

    /// SF Symbol that reads as the work.
    var symbol: String {
        switch self {
        case .setup:      return "square.dashed"
        case .turn:       return "arrow.triangle.turn.up.right.diamond"
        case .reveal:     return "eye"
        case .reaction:   return "arrow.uturn.down"
        case .escalation: return "flame"
        case .idle:       return "pause"
        case .repeatBeat: return "repeat"
        }
    }
}
