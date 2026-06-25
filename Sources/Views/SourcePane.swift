import SwiftUI

/// The reading pane. Two modes:
///  - editing (no radiograph yet): a plain monospace editor to paste/type into.
///  - reading (radiographed): the source rendered with the focused passage
///    highlighted, auto-scrolled into view when a spine card is clicked.
struct SourcePane: View {
    @EnvironmentObject private var workbench: Workbench

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(Theme.paperEdge)
            if workbench.hasRadiograph {
                readingView
            } else {
                editingView
            }
        }
        .background(Theme.paper)
    }

    private var header: some View {
        HStack(spacing: 8) {
            Image(systemName: "doc.plaintext").foregroundStyle(Theme.inkDim)
            TextField(t("Titre", "Title"), text: $workbench.title)
                .textFieldStyle(.plain)
                .font(Theme.serif(14, .semibold))
                .foregroundStyle(Theme.ink)
            Spacer()
            Text(t("\(workbench.sourceText.count) car.", "\(workbench.sourceText.count) chars"))
                .font(Theme.mono(10))
                .foregroundStyle(Theme.inkFaint)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Theme.paperRaised)
    }

    // MARK: Editing

    private var editingView: some View {
        ZStack(alignment: .topLeading) {
            if workbench.sourceText.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text(t("Colle ton texte ici.", "Paste your text here."))
                        .font(Theme.serif(15))
                        .foregroundStyle(Theme.inkDim)
                    Text(t("Un scénario, un traitement, une liste de scènes, un essai, un chapitre. Puis : Radiographier.",
                           "A screenplay, treatment, scene list, essay, chapter. Then: X-ray."))
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.inkFaint)
                }
                .padding(18)
                .allowsHitTesting(false)
            }
            TextEditor(text: $workbench.sourceText)
                .font(Theme.mono(12.5))
                .foregroundStyle(Theme.ink)
                .scrollContentBackground(.hidden)
                .background(Theme.paper)
                .padding(10)
        }
    }

    // MARK: Reading (highlighted)

    private var readingView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                Text(highlightedAttributed)
                    .font(Theme.mono(12.5))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .id("source-body")

                // An invisible anchor placed at the highlight so we can scroll to it.
                Color.clear.frame(height: 1).id("highlight-anchor")
            }
            .background(Theme.paper)
            .onChange(of: highlightLowerOffset) {
                guard workbench.highlightRange != nil else { return }
                withAnimation(.easeInOut(duration: 0.3)) {
                    proxy.scrollTo("source-body", anchor: anchorPoint)
                }
            }
        }
    }

    /// An `Equatable` projection of the highlight position for `onChange`.
    private var highlightLowerOffset: Int? {
        guard let range = workbench.highlightRange else { return nil }
        return workbench.sourceText.distance(from: workbench.sourceText.startIndex,
                                             to: range.lowerBound)
    }

    /// Where in the body to scroll, approximated from the highlight's position
    /// in the document (top/center/bottom thirds), since AttributedString gives
    /// us no per-glyph geometry.
    private var anchorPoint: UnitPoint {
        guard let range = workbench.highlightRange else { return .top }
        let total = workbench.sourceText.count
        guard total > 0 else { return .top }
        let pos = workbench.sourceText.distance(from: workbench.sourceText.startIndex,
                                                to: range.lowerBound)
        let frac = Double(pos) / Double(total)
        if frac < 0.33 { return .top }
        if frac < 0.66 { return .center }
        return .bottom
    }

    private var highlightedAttributed: AttributedString {
        var attr = AttributedString(workbench.sourceText)
        attr.foregroundColor = Theme.ink
        guard let range = workbench.highlightRange,
              let lower = AttributedString.Index(range.lowerBound, within: attr),
              let upper = AttributedString.Index(range.upperBound, within: attr),
              lower < upper else {
            return attr
        }
        attr[lower..<upper].backgroundColor = Theme.blueprint.opacity(0.22)
        attr[lower..<upper].foregroundColor = Theme.ink
        return attr
    }
}
