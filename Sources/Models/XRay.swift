import Foundation
import SwiftData

/// A saved radiograph of a document. We persist the source text plus the
/// analysis as JSON blobs (the `StoryUnit` / `StructuralHole` value types are
/// `Codable`), which keeps the schema dead simple and lets the analysis shape
/// evolve without SwiftData migrations.
///
/// Saving is always EXPLICIT — L'Envers never auto-overwrites Jac's work.
@Model
final class XRay {
    /// A human title (defaults to the first line of the source).
    var title: String
    /// The full source text, verbatim.
    var sourceText: String
    /// JSON-encoded `[StoryUnit]`.
    private var unitsData: Data
    /// JSON-encoded `[StructuralHole]`.
    private var holesData: Data
    /// When this radiograph was taken.
    var createdAt: Date
    /// When it was last re-radiographed / edited.
    var updatedAt: Date

    init(title: String, sourceText: String, units: [StoryUnit], holes: [StructuralHole]) {
        self.title = title
        self.sourceText = sourceText
        self.unitsData = (try? JSONEncoder().encode(units)) ?? Data()
        self.holesData = (try? JSONEncoder().encode(holes)) ?? Data()
        let now = Date()
        self.createdAt = now
        self.updatedAt = now
    }

    var units: [StoryUnit] {
        get { (try? JSONDecoder().decode([StoryUnit].self, from: unitsData)) ?? [] }
        set { unitsData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    var holes: [StructuralHole] {
        get { (try? JSONDecoder().decode([StructuralHole].self, from: holesData)) ?? [] }
        set { holesData = (try? JSONEncoder().encode(newValue)) ?? Data() }
    }

    /// Update an existing radiograph in place (explicit re-save).
    func apply(_ result: AnalysisResult) {
        units = result.units
        holes = result.holes
        updatedAt = Date()
    }
}
