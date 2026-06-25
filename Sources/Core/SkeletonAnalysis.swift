import Foundation

/// Pure structural analysis run *locally* over the model's output. None of this
/// touches the network: given the ordered units, it finds the dramatically dead
/// zones (flatlines on the tension EKG) and clusters units that do the same job
/// (repeats). These are the two derived signals the spine and EKG draw, and they
/// are the heart of the unit tests.
enum SkeletonAnalysis {

    // MARK: Flatlines

    /// A contiguous stretch of units whose tension barely moves — the "dead zone".
    struct Flatline: Equatable {
        /// Inclusive range of unit indices (into the units array, 0-based positions).
        var range: ClosedRange<Int>
        /// The mean tension across the stretch (for shading intensity).
        var level: Double
        var count: Int { range.count }
    }

    /// Find flatline stretches: runs of `minRun` or more consecutive units that
    /// all sit within `delta` tension of each other (max − min ≤ delta).
    ///
    /// Greedy and maximal: a run extends as long as adding the next unit keeps
    /// the whole run inside the band, then the next run starts fresh. Overlapping
    /// shorter runs are never reported — each unit belongs to at most one flatline.
    ///
    /// - Parameters:
    ///   - units: ordered units (any order; we read `tension` positionally).
    ///   - delta: max tension spread allowed inside a flatline (default 0.08).
    ///   - minRun: minimum consecutive units to count as a flatline (default 3).
    static func flatlines(in units: [StoryUnit],
                          delta: Double = 0.08,
                          minRun: Int = 3) -> [Flatline] {
        guard units.count >= minRun, minRun >= 1 else { return [] }
        let t = units.map { $0.tension }

        var result: [Flatline] = []
        var start = 0
        var runMin = t[0]
        var runMax = t[0]

        func flush(end: Int) {
            // run is [start, end] inclusive
            let length = end - start + 1
            if length >= minRun {
                let slice = t[start...end]
                let mean = slice.reduce(0, +) / Double(length)
                result.append(Flatline(range: start...end, level: mean))
            }
        }

        var i = 1
        while i < t.count {
            let newMin = Swift.min(runMin, t[i])
            let newMax = Swift.max(runMax, t[i])
            if newMax - newMin <= delta {
                // extend the current run
                runMin = newMin
                runMax = newMax
            } else {
                // close the run at i-1, then start a fresh run at i
                flush(end: i - 1)
                start = i
                runMin = t[i]
                runMax = t[i]
            }
            i += 1
        }
        flush(end: t.count - 1)
        return result
    }

    /// Convenience: the set of unit positions that fall inside any flatline.
    static func flatlineIndices(in units: [StoryUnit],
                                delta: Double = 0.08,
                                minRun: Int = 3) -> Set<Int> {
        var s = Set<Int>()
        for f in flatlines(in: units, delta: delta, minRun: minRun) {
            for p in f.range { s.insert(p) }
        }
        return s
    }

    // MARK: Repeat clusters

    /// A group of units that do the same dramatic job — either the model typed
    /// them `repeat`, or their `function` verb phrases are near-identical.
    struct RepeatCluster: Equatable, Identifiable {
        var id: Int { positions.first ?? -1 }
        /// Positions (into the units array) sharing the same job.
        var positions: [Int]
        /// A representative normalized function string for the cluster.
        var signature: String
    }

    /// Cluster units that share a near-identical `function`. Units the model
    /// explicitly typed `repeat` are folded into the cluster matching their
    /// function (or, failing that, grouped together as their own cluster).
    ///
    /// Matching is on a normalized form of the function phrase: lowercased,
    /// diacritics and punctuation stripped, collapsed whitespace, and a few
    /// French function-word stop-tokens removed so "retarde la révélation" and
    /// "retarde révélation" land together. Only clusters of 2+ are returned.
    static func repeatClusters(in units: [StoryUnit]) -> [RepeatCluster] {
        guard !units.isEmpty else { return [] }

        // Bucket positions by normalized function signature.
        var buckets: [String: [Int]] = [:]
        var order: [String] = []
        for (pos, u) in units.enumerated() {
            let sig = normalize(u.function)
            guard !sig.isEmpty else { continue }
            if buckets[sig] == nil { order.append(sig) }
            buckets[sig, default: []].append(pos)
        }

        var clusters: [RepeatCluster] = []
        for sig in order {
            let positions = buckets[sig] ?? []
            if positions.count >= 2 {
                clusters.append(RepeatCluster(positions: positions, signature: sig))
            }
        }

        // Any unit explicitly typed `repeat` that didn't already land in a 2+
        // cluster is still a repeat by the model's judgement — surface those
        // together so the spine can colour them.
        let clustered = Set(clusters.flatMap { $0.positions })
        let lonelyRepeats = units.enumerated()
            .filter { $0.element.type == .repeatBeat && !clustered.contains($0.offset) }
            .map { $0.offset }
        if lonelyRepeats.count >= 2 {
            clusters.append(RepeatCluster(positions: lonelyRepeats, signature: t("redite", "repeat")))
        }

        return clusters
    }

    /// The set of unit positions that participate in any repeat cluster.
    static func repeatedIndices(in units: [StoryUnit]) -> Set<Int> {
        Set(repeatClusters(in: units).flatMap { $0.positions })
    }

    /// Map each repeated position to a stable cluster ordinal (0,1,2…) so the
    /// UI can give each "same job" group its own marker.
    static func clusterTag(in units: [StoryUnit]) -> [Int: Int] {
        var tag: [Int: Int] = [:]
        for (ordinal, cluster) in repeatClusters(in: units).enumerated() {
            for p in cluster.positions { tag[p] = ordinal }
        }
        return tag
    }

    // MARK: Normalization

    /// Normalize a function phrase for repeat matching.
    static func normalize(_ s: String) -> String {
        let folded = s.folding(options: [.diacriticInsensitive, .caseInsensitive],
                               locale: Locale(identifier: "fr"))
        // Keep letters and spaces only.
        let cleaned = folded.unicodeScalars.map { scalar -> Character in
            if CharacterSet.letters.contains(scalar) { return Character(scalar) }
            return " "
        }
        let tokens = String(cleaned)
            .split(separator: " ")
            .map(String.init)
            .filter { !stopWords.contains($0) && $0.count > 1 }
        return tokens.joined(separator: " ")
    }

    /// Tiny French/English function-word list, so the *content* verbs drive
    /// matching rather than articles and prepositions.
    private static let stopWords: Set<String> = [
        "le", "la", "les", "un", "une", "des", "de", "du", "au", "aux",
        "et", "ou", "a", "the", "of", "to", "and", "or", "se", "sa", "son",
        "ses", "ce", "cette", "ces", "que", "qui", "en", "dans", "sur", "with",
    ]
}
