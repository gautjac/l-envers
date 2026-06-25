import XCTest
@testable import LEnvers

/// Pure logic tests for the two derived structural signals — flatline detection
/// on the tension EKG, and repeat clustering of units that do the same job.
/// No network, no UI: just the math L'Envers draws.
final class SkeletonAnalysisTests: XCTestCase {

    // MARK: Builders

    private func unit(_ i: Int, _ tension: Double, function: String = "fait quelque chose",
                      type: UnitType = .setup) -> StoryUnit {
        StoryUnit(index: i, label: "U\(i)", function: function, type: type, tension: tension)
    }

    private func units(_ tensions: [Double]) -> [StoryUnit] {
        tensions.enumerated().map { unit($0.offset, $0.element) }
    }

    // MARK: Flatline detection

    func testNoFlatlineWhenTooFewUnits() {
        XCTAssertTrue(SkeletonAnalysis.flatlines(in: units([0.3, 0.3])).isEmpty)
    }

    func testDetectsASingleFlatStretch() {
        // Three identical-tension units in the middle of a varied curve.
        let u = units([0.1, 0.5, 0.5, 0.5, 0.9])
        let fl = SkeletonAnalysis.flatlines(in: u)
        XCTAssertEqual(fl.count, 1)
        XCTAssertEqual(fl.first?.range, 1...3)
        XCTAssertEqual(fl.first?.count, 3)
        XCTAssertEqual(fl.first?.level ?? 0, 0.5, accuracy: 1e-9)
    }

    func testFlatStretchWithinDeltaCounts() {
        // 0.40, 0.44, 0.46 — spread 0.06 ≤ default delta 0.08 → flat.
        let u = units([0.10, 0.40, 0.44, 0.46, 0.95])
        let fl = SkeletonAnalysis.flatlines(in: u)
        XCTAssertEqual(fl.first?.range, 1...3)
    }

    func testSpreadAboveDeltaBreaksTheRun() {
        // 0.40, 0.44, 0.60 — once 0.60 joins, spread 0.20 > delta, so the run
        // closes before it ever reaches length 3 → no flatline.
        let u = units([0.40, 0.44, 0.60, 0.95])
        XCTAssertTrue(SkeletonAnalysis.flatlines(in: u).isEmpty)
    }

    func testEntirelyFlatDocumentIsOneFlatline() {
        let u = units([0.5, 0.5, 0.5, 0.5, 0.5])
        let fl = SkeletonAnalysis.flatlines(in: u)
        XCTAssertEqual(fl.count, 1)
        XCTAssertEqual(fl.first?.range, 0...4)
    }

    func testTwoSeparateFlatlines() {
        // flat [0.2,0.2,0.2], spike, flat [0.8,0.8,0.8]
        let u = units([0.2, 0.2, 0.2, 0.55, 0.8, 0.8, 0.8])
        let fl = SkeletonAnalysis.flatlines(in: u)
        XCTAssertEqual(fl.count, 2)
        XCTAssertEqual(fl[0].range, 0...2)
        XCTAssertEqual(fl[1].range, 4...6)
    }

    func testShortRunBelowMinIsNotFlat() {
        // Only two equal in a row → below minRun 3.
        let u = units([0.1, 0.5, 0.5, 0.9, 0.2])
        XCTAssertTrue(SkeletonAnalysis.flatlines(in: u).isEmpty)
    }

    func testFlatlineIndicesCoverTheStretch() {
        let u = units([0.1, 0.5, 0.5, 0.5, 0.9])
        XCTAssertEqual(SkeletonAnalysis.flatlineIndices(in: u), [1, 2, 3])
    }

    func testGreedyRunIsMaximalNotOverlapping() {
        // A long flat stretch should be ONE flatline of 4, not two of 3.
        let u = units([0.9, 0.3, 0.3, 0.3, 0.3, 0.95])
        let fl = SkeletonAnalysis.flatlines(in: u)
        XCTAssertEqual(fl.count, 1)
        XCTAssertEqual(fl.first?.range, 1...4)
        XCTAssertEqual(fl.first?.count, 4)
    }

    func testCustomDeltaAndMinRun() {
        let u = units([0.0, 0.1, 0.2, 0.9])
        // With a generous delta, the rising 0,0.1,0.2 (spread 0.2) counts.
        let fl = SkeletonAnalysis.flatlines(in: u, delta: 0.25, minRun: 3)
        XCTAssertEqual(fl.first?.range, 0...2)
    }

    // MARK: Repeat clustering

    func testIdenticalFunctionsCluster() {
        let u = [
            unit(0, 0.4, function: "retarde la révélation"),
            unit(1, 0.5, function: "escalade le conflit"),
            unit(2, 0.4, function: "retarde la révélation"),
        ]
        let clusters = SkeletonAnalysis.repeatClusters(in: u)
        XCTAssertEqual(clusters.count, 1)
        XCTAssertEqual(clusters.first?.positions, [0, 2])
    }

    func testNearIdenticalFunctionsClusterViaNormalization() {
        // Articles/diacritics/case differ but the content verbs match.
        let u = [
            unit(0, 0.4, function: "Retarde la Révélation"),
            unit(1, 0.4, function: "retarde révélation"),
            unit(2, 0.4, function: "presente le héros"),
        ]
        let clusters = SkeletonAnalysis.repeatClusters(in: u)
        XCTAssertEqual(clusters.count, 1)
        XCTAssertEqual(clusters.first?.positions, [0, 1])
    }

    func testDistinctFunctionsDoNotCluster() {
        let u = [
            unit(0, 0.4, function: "présente le héros"),
            unit(1, 0.5, function: "escalade le conflit"),
            unit(2, 0.6, function: "révèle la trahison"),
        ]
        XCTAssertTrue(SkeletonAnalysis.repeatClusters(in: u).isEmpty)
    }

    func testRepeatTypedUnitsClusterEvenWithDifferentWording() {
        // Two units typed `repeat` whose functions don't textually match still
        // get grouped as a "lonely repeats" cluster.
        let u = [
            unit(0, 0.3, function: "ramene le doute", type: .repeatBeat),
            unit(1, 0.5, function: "tourne la page", type: .turn),
            unit(2, 0.3, function: "revient sur la blessure autrement", type: .repeatBeat),
        ]
        let clusters = SkeletonAnalysis.repeatClusters(in: u)
        XCTAssertEqual(clusters.count, 1)
        XCTAssertEqual(clusters.first?.positions, [0, 2])
    }

    func testRepeatTypedUnitFoldsIntoMatchingFunctionCluster() {
        // A `repeat`-typed unit whose function matches an earlier one joins that
        // text cluster rather than forming a separate lonely-repeats group.
        let u = [
            unit(0, 0.4, function: "ré-énonce la blessure"),
            unit(1, 0.5, function: "escalade"),
            unit(2, 0.4, function: "ré-énonce la blessure", type: .repeatBeat),
        ]
        let clusters = SkeletonAnalysis.repeatClusters(in: u)
        XCTAssertEqual(clusters.count, 1)
        XCTAssertEqual(clusters.first?.positions, [0, 2])
    }

    func testMultipleDistinctClustersGetStableTags() {
        let u = [
            unit(0, 0.4, function: "retarde la révélation"),
            unit(1, 0.5, function: "escalade le conflit"),
            unit(2, 0.4, function: "retarde la révélation"),
            unit(3, 0.5, function: "escalade le conflit"),
        ]
        let tags = SkeletonAnalysis.clusterTag(in: u)
        // Two clusters: {0,2}=0 and {1,3}=1 (order by first appearance).
        XCTAssertEqual(tags[0], 0)
        XCTAssertEqual(tags[2], 0)
        XCTAssertEqual(tags[1], 1)
        XCTAssertEqual(tags[3], 1)
    }

    func testRepeatedIndicesUnion() {
        let u = [
            unit(0, 0.4, function: "retarde la révélation"),
            unit(1, 0.5, function: "escalade le conflit"),
            unit(2, 0.4, function: "retarde la révélation"),
        ]
        XCTAssertEqual(SkeletonAnalysis.repeatedIndices(in: u), [0, 2])
    }

    func testEmptyFunctionsAreIgnored() {
        let u = [
            unit(0, 0.4, function: ""),
            unit(1, 0.5, function: ""),
        ]
        XCTAssertTrue(SkeletonAnalysis.repeatClusters(in: u).isEmpty)
    }

    func testNormalizeStripsStopWordsAndDiacritics() {
        XCTAssertEqual(SkeletonAnalysis.normalize("Retarde la Révélation"),
                       SkeletonAnalysis.normalize("retarde révélation"))
        // Punctuation (incl. hyphens) becomes a token boundary, diacritics drop,
        // stop-words are removed, whitespace collapses. The result is stable, so
        // any two spellings of the same phrase normalize identically.
        XCTAssertEqual(SkeletonAnalysis.normalize("ré-énonce  la   blessure!"),
                       "re enonce blessure")
        XCTAssertEqual(SkeletonAnalysis.normalize("RÉ-ÉNONCE la Blessure"),
                       SkeletonAnalysis.normalize("ré-énonce  la   blessure!"))
    }

    // MARK: Source locating

    func testSourceLocatorFindsExactQuote() {
        let text = "Il entre dans la pièce. Elle ne lève pas les yeux."
        let r = SourceLocator.range(of: "Elle ne lève pas les yeux", in: text)
        XCTAssertNotNil(r)
    }

    func testSourceLocatorIsWhitespaceTolerant() {
        let text = "Première ligne.\n\n   Deuxième    ligne ici."
        let r = SourceLocator.range(of: "Deuxième ligne ici", in: text)
        XCTAssertNotNil(r)
    }

    func testSourceLocatorReturnsNilForAbsentQuote() {
        let text = "Un texte tout à fait ordinaire."
        XCTAssertNil(SourceLocator.range(of: "phrase qui n'existe pas du tout ici", in: text))
    }
}
