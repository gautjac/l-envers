import Foundation

/// Locates a unit's `sourceQuote` inside the full document so a click on a spine
/// card can scroll to and highlight the matching passage. Tries progressively
/// looser matching, and fails gracefully (returns nil) rather than guessing.
enum SourceLocator {

    /// Find the character range of `quote` within `text`. Returns nil if no
    /// reasonable match exists.
    static func range(of quote: String, in text: String) -> Range<String.Index>? {
        let q = quote.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty, !text.isEmpty else { return nil }

        // 1) Exact, case-insensitive, diacritic-insensitive.
        if let r = text.range(of: q, options: [.caseInsensitive, .diacriticInsensitive]) {
            return r
        }

        // 2) Whitespace-tolerant: the model often collapses newlines/spaces in
        //    its quote. Match on a normalized projection, then map back.
        if let r = whitespaceTolerantRange(of: q, in: text) { return r }

        // 3) Anchor on the first distinctive run of words (>= 4 words), in case
        //    the model paraphrased the tail of the quote.
        let words = q.split(whereSeparator: { $0 == " " || $0 == "\n" }).map(String.init)
        if words.count >= 4 {
            let head = words.prefix(min(6, words.count)).joined(separator: " ")
            if let r = text.range(of: head, options: [.caseInsensitive, .diacriticInsensitive]) {
                return r
            }
            if let r = whitespaceTolerantRange(of: head, in: text) { return r }
        }
        return nil
    }

    /// Match ignoring differences in runs of whitespace.
    private static func whitespaceTolerantRange(of quote: String, in text: String) -> Range<String.Index>? {
        // Build a normalized copy of `text` plus an index map back to the original.
        var normChars: [Character] = []
        var map: [String.Index] = []   // map[i] = original index that produced normChars[i]
        var lastWasSpace = false
        var idx = text.startIndex
        while idx < text.endIndex {
            let ch = text[idx]
            if ch.isWhitespace {
                if !lastWasSpace {
                    normChars.append(" ")
                    map.append(idx)
                    lastWasSpace = true
                }
            } else {
                normChars.append(Character(ch.lowercased()))
                map.append(idx)
                lastWasSpace = false
            }
            idx = text.index(after: idx)
        }
        let normText = String(normChars)
        let normQuote = quote
            .folding(options: [.caseInsensitive], locale: nil)
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
            .lowercased()
        guard !normQuote.isEmpty,
              let nr = normText.range(of: normQuote) else { return nil }

        let lower = normText.distance(from: normText.startIndex, to: nr.lowerBound)
        let upper = normText.distance(from: normText.startIndex, to: nr.upperBound)
        guard lower < map.count else { return nil }
        let startOrig = map[lower]
        let endOrig = upper - 1 < map.count ? text.index(after: map[upper - 1]) : text.endIndex
        guard startOrig <= endOrig else { return nil }
        return startOrig..<endOrig
    }
}
