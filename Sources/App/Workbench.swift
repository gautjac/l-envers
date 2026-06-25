import Foundation
import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import AppKit

/// The working state of the editor window: the document currently on the
/// drafting table, its radiograph (if any), the analysis phase, and the
/// current selection/highlight wiring between the spine, the EKG, the holes
/// panel and the source pane.
@MainActor
final class Workbench: ObservableObject {

    enum Phase: Equatable {
        case idle
        case analyzing
        case ready
        case failed(String)
    }

    /// The raw source text on the table.
    @Published var sourceText: String = ""
    /// A human title (editable; seeded from the first line).
    @Published var title: String = ""
    /// The ordered units of the current radiograph.
    @Published var units: [StoryUnit] = []
    /// The structural holes.
    @Published var holes: [StructuralHole] = []
    /// Where we are.
    @Published var phase: Phase = .idle

    /// The unit position currently focused (clicked on the spine / EKG).
    @Published var focusedUnit: Int?
    /// The hole currently selected (lights up its units).
    @Published var selectedHole: StructuralHole.ID?
    /// The source range to scroll-to / highlight, recomputed on focus.
    @Published var highlightRange: Range<String.Index>?

    /// The persisted record this workbench is bound to, if it was opened/saved.
    @Published var boundXRayID: PersistentIdentifier?
    /// True when the in-memory radiograph differs from what's saved.
    @Published var isDirty: Bool = false

    private let radiographer = Radiographer()

    // MARK: Derived structural signals (local, no network)

    var flatlineIndices: Set<Int> { SkeletonAnalysis.flatlineIndices(in: units) }
    var flatlines: [SkeletonAnalysis.Flatline] { SkeletonAnalysis.flatlines(in: units) }
    var repeatedIndices: Set<Int> { SkeletonAnalysis.repeatedIndices(in: units) }
    var clusterTags: [Int: Int] { SkeletonAnalysis.clusterTag(in: units) }

    var hasRadiograph: Bool { !units.isEmpty }

    /// Units implicated by the currently selected hole.
    var highlightedUnitsFromHole: Set<Int> {
        guard let id = selectedHole, let hole = holes.first(where: { $0.id == id }) else { return [] }
        return Set(hole.unitIndices)
    }

    // MARK: Intake

    func loadText(_ text: String, title suggested: String? = nil) {
        sourceText = text
        title = suggested ?? Self.deriveTitle(from: text)
        resetAnalysis()
    }

    /// Open a .txt / .md / .fountain file via the standard open panel.
    func openFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        var types: [UTType] = [.plainText, .text]
        if let md = UTType(filenameExtension: "md") { types.append(md) }
        if let fountain = UTType(filenameExtension: "fountain") { types.append(fountain) }
        if let markdown = UTType(filenameExtension: "markdown") { types.append(markdown) }
        panel.allowedContentTypes = types
        panel.allowsOtherFileTypes = true
        if panel.runModal() == .OK, let url = panel.url {
            if let data = try? Data(contentsOf: url),
               let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) {
                loadText(text, title: url.deletingPathExtension().lastPathComponent)
            }
        }
    }

    private func resetAnalysis() {
        units = []
        holes = []
        phase = .idle
        focusedUnit = nil
        selectedHole = nil
        highlightRange = nil
        boundXRayID = nil
        isDirty = false
    }

    // MARK: Radiograph

    func radiograph() async {
        let doc = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !doc.isEmpty else { phase = .failed(XRayError.emptyDocument.localizedDescription); return }
        phase = .analyzing
        focusedUnit = nil
        selectedHole = nil
        highlightRange = nil
        do {
            let result = try await radiographer.radiograph(text: sourceText)
            units = result.units
            holes = result.holes
            phase = .ready
            isDirty = true
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            phase = .failed(message)
        }
    }

    // MARK: Focus / highlight wiring

    func focus(unitAt position: Int) {
        focusedUnit = position
        selectedHole = nil
        recomputeHighlight()
    }

    func selectHole(_ hole: StructuralHole) {
        selectedHole = (selectedHole == hole.id) ? nil : hole.id
        // Focus the first implicated unit so the source pane jumps there too.
        if selectedHole != nil, let first = hole.unitIndices.first,
           units.indices.contains(first) {
            focusedUnit = first
            recomputeHighlight()
        }
    }

    private func recomputeHighlight() {
        guard let pos = focusedUnit, units.indices.contains(pos) else {
            highlightRange = nil
            return
        }
        highlightRange = SourceLocator.range(of: units[pos].sourceQuote, in: sourceText)
    }

    // MARK: Persistence (explicit)

    /// Save a NEW radiograph (or overwrite the bound one if `asNew` is false).
    func save(into context: ModelContext, asNew: Bool = false) {
        guard hasRadiograph else { return }
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalTitle = cleanTitle.isEmpty ? Self.deriveTitle(from: sourceText) : cleanTitle

        if !asNew, let id = boundXRayID,
           let existing = context.model(for: id) as? XRay {
            existing.title = finalTitle
            existing.sourceText = sourceText
            existing.apply(AnalysisResult(units: units, holes: holes))
        } else {
            let record = XRay(title: finalTitle, sourceText: sourceText, units: units, holes: holes)
            context.insert(record)
            boundXRayID = record.persistentModelID
        }
        try? context.save()
        isDirty = false
    }

    /// Load a saved radiograph onto the table.
    func open(_ record: XRay) {
        sourceText = record.sourceText
        title = record.title
        units = record.units
        holes = record.holes
        phase = units.isEmpty ? .idle : .ready
        focusedUnit = nil
        selectedHole = nil
        highlightRange = nil
        boundXRayID = record.persistentModelID
        isDirty = false
    }

    /// Clear the table for a fresh document.
    func newDocument() {
        sourceText = ""
        title = ""
        resetAnalysis()
    }

    // MARK: Helpers

    static func deriveTitle(from text: String) -> String {
        let firstLine = text
            .split(whereSeparator: { $0 == "\n" })
            .first.map(String.init)?
            .trimmingCharacters(in: .whitespaces) ?? ""
        let cleaned = firstLine
            .replacingOccurrences(of: "#", with: "")
            .trimmingCharacters(in: .whitespaces)
        if cleaned.isEmpty { return t("Sans titre", "Untitled") }
        return String(cleaned.prefix(60))
    }
}
