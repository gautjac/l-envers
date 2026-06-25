import Foundation

/// One unit of the X-ray: a scene/beat/paragraph and the *job it does*.
///
/// This is the value type the analyzer produces and the persistence layer
/// freezes into SwiftData (as a `Codable` blob on `XRay`). Coordinates of the
/// source are recovered at view time via `sourceQuote`, so the unit survives
/// any later re-flow of the text.
struct StoryUnit: Identifiable, Codable, Equatable {
    var id = UUID()
    /// Order in the document, 0-based.
    var index: Int
    /// A short verbatim anchor snippet that exists in the source text.
    var sourceQuote: String
    /// A 2–4 word handle, FR-first.
    var label: String
    /// The dramatic/rhetorical job, as a VERB phrase: "retarde la révélation".
    var function: String
    /// The kind of work (colour code).
    var type: UnitType
    /// Dramatic tension at this unit, 0…1.
    var tension: Double
    /// Optional one-line note from the model.
    var note: String?

    enum CodingKeys: String, CodingKey {
        case index, sourceQuote, label, function, type, tension, note
    }

    /// Decode from the model's wire JSON (where `type` is a raw string incl. "repeat").
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        index = try c.decode(Int.self, forKey: .index)
        sourceQuote = (try? c.decode(String.self, forKey: .sourceQuote)) ?? ""
        label = (try? c.decode(String.self, forKey: .label)) ?? ""
        function = (try? c.decode(String.self, forKey: .function)) ?? ""
        let rawType = (try? c.decode(String.self, forKey: .type)) ?? "idle"
        type = UnitType(wire: rawType)
        tension = min(max((try? c.decode(Double.self, forKey: .tension)) ?? 0, 0), 1)
        note = try? c.decode(String.self, forKey: .note)
    }

    /// Re-encode (used when persisting); writes the model-style raw type.
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(index, forKey: .index)
        try c.encode(sourceQuote, forKey: .sourceQuote)
        try c.encode(label, forKey: .label)
        try c.encode(function, forKey: .function)
        try c.encode(type == .repeatBeat ? "repeat" : type.rawValue, forKey: .type)
        try c.encode(tension, forKey: .tension)
        try c.encodeIfPresent(note, forKey: .note)
    }

    /// Direct memberwise init (tests, previews).
    init(index: Int, sourceQuote: String = "", label: String, function: String,
         type: UnitType, tension: Double, note: String? = nil) {
        self.index = index
        self.sourceQuote = sourceQuote
        self.label = label
        self.function = function
        self.type = type
        self.tension = min(max(tension, 0), 1)
        self.note = note
    }
}

/// A structural diagnosis: a hole in the skeleton. "Trois scènes font le même
/// travail au 2e acte", "aucun retournement entre la mise en place et le climax".
struct StructuralHole: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var detail: String
    /// The unit indices implicated, so clicking the hole can light them up.
    var unitIndices: [Int]

    enum CodingKeys: String, CodingKey { case title, detail, unitIndices }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        title = (try? c.decode(String.self, forKey: .title)) ?? ""
        detail = (try? c.decode(String.self, forKey: .detail)) ?? ""
        unitIndices = (try? c.decode([Int].self, forKey: .unitIndices)) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(title, forKey: .title)
        try c.encode(detail, forKey: .detail)
        try c.encode(unitIndices, forKey: .unitIndices)
    }

    init(title: String, detail: String, unitIndices: [Int]) {
        self.title = title
        self.detail = detail
        self.unitIndices = unitIndices
    }
}

/// The complete reverse-outline of a document: the ordered units plus the holes.
struct AnalysisResult: Codable, Equatable {
    var units: [StoryUnit]
    var holes: [StructuralHole]
}
