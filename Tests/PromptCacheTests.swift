import XCTest
@testable import LEnvers

/// Prompt caching on the radiograph: the tool schema and system prompt must encode to
/// the same bytes on every radiograph (they render first, ahead of the breakpoint), and
/// only the document — in the user turn, after the breakpoint — may change when the
/// writer re-radiographs an edited draft.
///
/// Set `CACHE_DUMP_DIR` (`TEST_RUNNER_CACHE_DUMP_DIR=… xcodebuild test`) to also write
/// the exact wire bodies (draft, then edited draft) for a live cache check.
final class PromptCacheTests: XCTestCase {

    private let radiographer = Radiographer()

    /// A short treatment, the kind of page L'Envers is fed.
    private let draft = """
    LA PATIENCE — traitement, version 3

    1. Le quai de Cocagne, à l'aube. Irène, 58 ans, répare un casier à homards qu'elle ne \
    posera jamais. Son fils Marc arrive de Moncton sans prévenir, une valise à la main.

    2. La cuisine. Irène sert du thé. Marc parle de son travail, de l'appartement, du prix \
    de l'essence. Elle écoute en comptant les sachets de thé dans la boîte.

    3. Le garage. Marc trouve le bateau de son père sous une bâche, intact. Irène dit \
    qu'elle le garde « pour quand ». Elle ne finit pas la phrase.

    4. Le souper chez la voisine, Léonie. On parle de la pêche, des quotas, des jeunes qui \
    partent. Léonie demande à Marc s'il reste. Il ne répond pas.

    5. La nuit. Marc fouille le bureau de son père et trouve une lettre de la banque : la \
    maison est hypothéquée depuis deux ans. Irène n'en a jamais parlé.

    6. Le lendemain, au quai. Marc confronte Irène. Elle répond en réparant le casier. \
    Elle dit qu'elle a payé les médicaments. Elle dit qu'elle aurait vendu le bateau, mais \
    que le bateau, c'était lui.

    7. L'église, les funérailles d'un vieux pêcheur. Irène chante. Marc la regarde chanter \
    comme s'il la voyait pour la première fois.

    8. Le garage. Marc enlève la bâche. Il vérifie le moteur. Irène le regarde faire depuis \
    la porte, sans entrer.

    9. Le quai, au crépuscule. Le bateau est à l'eau. Marc ne dit pas s'il reste. Irène \
    pose enfin le casier.
    """

    private var editedDraft: String {
        draft.replacingOccurrences(
            of: "On parle de la pêche, des quotas, des jeunes qui partent. Léonie demande à Marc s'il reste. Il ne répond pas.",
            with: "Léonie sait pour l'hypothèque ; elle se tait quand Irène change de sujet. Marc remarque le silence sans le comprendre.")
    }

    private func object(_ data: Data) throws -> [String: Any] {
        try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func canonical(_ value: Any?) throws -> Data {
        try JSONSerialization.data(withJSONObject: try XCTUnwrap(value), options: [.sortedKeys])
    }

    func testRadiographBodyEncodesToTheSameBytes() throws {
        // Fresh dictionary instances (the schema is rebuilt each time): one encoding.
        let encodings = try Set((0..<40).map { _ in
            try Radiographer.encode(radiographer.requestBody(document: draft, french: true))
        })
        XCTAssertEqual(encodings.count, 1)
    }

    func testReRadiographSharesToolsAndSystem() throws {
        XCTAssertNotEqual(draft, editedDraft)
        let first = try Radiographer.encode(radiographer.requestBody(document: draft, french: true))
        let second = try Radiographer.encode(radiographer.requestBody(document: editedDraft, french: true))
        let a = try object(first), b = try object(second)

        XCTAssertEqual(try canonical(a["tools"]), try canonical(b["tools"]))
        XCTAssertEqual(try canonical(a["system"]), try canonical(b["system"]))

        let system = try XCTUnwrap(a["system"] as? [[String: Any]])
        let marker = try XCTUnwrap(system.last?["cache_control"] as? [String: Any])
        XCTAssertEqual(marker["type"] as? String, "ephemeral")

        // Only the document, after the breakpoint, differs.
        XCTAssertNotEqual(try canonical(a["messages"]), try canonical(b["messages"]))

        if let dir = ProcessInfo.processInfo.environment["CACHE_DUMP_DIR"], !dir.isEmpty {
            let folder = URL(fileURLWithPath: dir, isDirectory: true)
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
            try first.write(to: folder.appendingPathComponent("1.json"))
            try second.write(to: folder.appendingPathComponent("2.json"))
        }
    }
}
