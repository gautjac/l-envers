import Foundation

/// Calls Anthropic's Messages API directly over HTTPS (Swift has no official SDK),
/// sending whatever document the user asked to radiograph. A forced `tool_use` makes
/// `claude-opus-4-8` return STRICT structured JSON — the ordered units of the story's
/// skeleton plus a list of structural holes — instead of prose.
///
/// The system prompt is the whole idea of the app: don't summarize what each unit
/// *says*, name what it *does*. Read for structure, not content. Be honest about
/// dead stretches, repeats, and missing turns.
///
/// `Sendable` + `async` so the UI can await a radiograph without blocking.
struct Radiographer: Sendable {
    private let model = "claude-opus-4-8"
    private let endpoint = URL(string: "https://api.anthropic.com/v1/messages")!
    private let anthropicVersion = "2023-06-01"

    /// Radiograph a document; returns the ordered units and the structural holes.
    func radiograph(text: String, french: Bool = prefersFrench) async throws -> AnalysisResult {
        let doc = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !doc.isEmpty else { throw XRayError.emptyDocument }
        guard let key = Keychain.apiKey(), !key.isEmpty else { throw XRayError.missingKey }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(key, forHTTPHeaderField: "x-api-key")
        request.setValue(anthropicVersion, forHTTPHeaderField: "anthropic-version")
        request.httpBody = try Self.encode(requestBody(document: doc, french: french))
        request.timeoutInterval = 180

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw XRayError.transport(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw XRayError.transport(t("réponse non-HTTP", "non-HTTP response"))
        }
        guard (200..<300).contains(http.statusCode) else {
            throw XRayError.http(status: http.statusCode, message: Self.errorMessage(from: data))
        }

        // Find the forced tool_use block and decode its input.
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = root["content"] as? [[String: Any]] else {
            throw XRayError.noToolUse
        }
        guard let toolUse = content.first(where: { ($0["type"] as? String) == "tool_use" }),
              let input = toolUse["input"] as? [String: Any] else {
            throw XRayError.noToolUse
        }

        do {
            let inputData = try JSONSerialization.data(withJSONObject: input)
            let decoded = try JSONDecoder().decode(SkeletonPayload.self, from: inputData)
            // Re-index defensively so positions are contiguous and ordered.
            let ordered = decoded.units.sorted { $0.index < $1.index }
            let reindexed = ordered.enumerated().map { (i, u) -> StoryUnit in
                var copy = u
                copy.index = i
                return copy
            }
            return AnalysisResult(units: reindexed, holes: decoded.holes)
        } catch {
            throw XRayError.decoding(error.localizedDescription)
        }
    }

    /// The radiograph request. The tool schema and the system prompt are the same on every
    /// radiograph, so the cache breakpoint closes the system block: re-radiographing an
    /// edited draft reads them back at a tenth of the price. The document follows, after
    /// the breakpoint, in the user turn.
    func requestBody(document doc: String, french: Bool) -> [String: Any] {
        [
            "model": model,
            "max_tokens": 8192,
            "system": [[
                "type": "text",
                "text": systemPrompt(french: french),
                "cache_control": ["type": "ephemeral"],
            ]],
            "tools": [[
                "name": "report_skeleton",
                "description": "Report the structural skeleton of the document: the ordered units (what each one DOES) and the structural holes.",
                "input_schema": schema,
            ]],
            // Force the answer THROUGH the tool — guarantees validated structured output.
            "tool_choice": ["type": "tool", "name": "report_skeleton"],
            "messages": [[
                "role": "user",
                "content": [[
                    "type": "text",
                    "text": userPrompt(french: french, document: doc),
                ]],
            ]],
        ]
    }

    /// Sorted keys: a Swift dictionary lists its keys in a different order from one
    /// instance (and one launch) to the next, and the prompt cache only matches identical
    /// bytes — the tool schema renders first, so one reshuffle loses the whole prefix.
    static func encode(_ body: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: body, options: [.sortedKeys])
    }

    // MARK: Wire payload

    private struct SkeletonPayload: Decodable {
        var units: [StoryUnit]
        var holes: [StructuralHole]

        enum CodingKeys: String, CodingKey { case units, holes }
        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            units = (try? c.decode([StoryUnit].self, forKey: .units)) ?? []
            holes = (try? c.decode([StructuralHole].self, forKey: .holes)) ?? []
        }
    }

    // MARK: Schema

    private var schema: [String: Any] {
        [
            "type": "object",
            "additionalProperties": false,
            "properties": [
                "units": [
                    "type": "array",
                    "description": "The document segmented into ordered structural units (scenes, beats, or paragraphs — chunk sensibly), each described by the JOB it does, not its content.",
                    "items": [
                        "type": "object",
                        "additionalProperties": false,
                        "properties": [
                            "index": ["type": "integer", "description": "0-based order in the document."],
                            "sourceQuote": ["type": "string", "description": "A SHORT verbatim anchor snippet (5–15 words) copied EXACTLY from the source text within this unit, so the app can locate the passage. Must exist verbatim in the document."],
                            "label": ["type": "string", "description": "A 2–4 word handle for this unit."],
                            "function": ["type": "string", "description": "The dramatic/rhetorical JOB this unit does, as a VERB phrase: 'retarde la révélation', 'ré-énonce la blessure', 'ne fait rien'. Name the work, not the content."],
                            "type": [
                                "type": "string",
                                "enum": ["setup", "turn", "reveal", "reaction", "escalation", "idle", "repeat"],
                                "description": "setup=plants info; turn=reversal/decision; reveal=new info surfaces; reaction=absorbs the prior beat; escalation=raises stakes; idle=marks time, does nothing; repeat=does the same job as an earlier unit.",
                            ],
                            "tension": ["type": "number", "description": "Dramatic tension at this unit, 0.0 (flat/calm) to 1.0 (peak). Be honest — flat stretches should read as flat."],
                            "note": ["type": "string", "description": "Optional one-line observation."],
                        ],
                        "required": ["index", "sourceQuote", "label", "function", "type", "tension"],
                    ],
                ],
                "holes": [
                    "type": "array",
                    "description": "Structural diagnoses — problems the writer's eye glosses over. Examples: 'trois scènes font le même travail au 2e acte', 'aucun retournement entre la mise en place et le climax', 'la révélation arrive trop tôt'. Empty if the structure is genuinely sound.",
                    "items": [
                        "type": "object",
                        "additionalProperties": false,
                        "properties": [
                            "title": ["type": "string", "description": "A short diagnosis headline."],
                            "detail": ["type": "string", "description": "One or two sentences explaining the structural problem and what it costs."],
                            "unitIndices": [
                                "type": "array",
                                "items": ["type": "integer"],
                                "description": "The 0-based indices of the units implicated in this hole.",
                            ],
                        ],
                        "required": ["title", "detail", "unitIndices"],
                    ],
                ],
            ],
            "required": ["units", "holes"],
        ]
    }

    // MARK: Prompts

    private func systemPrompt(french: Bool) -> String {
        let language = french
            ? "Réponds en français québécois, précis et sans flatterie."
            : "Respond in English, precise and unflattering."
        return """
        You are the diagnostic eye behind L'Envers — a reverse-outliner that shows a writer the \
        hidden SKELETON of what they wrote: not what each unit SAYS, but what it DOES. \(language)

        You are given a document — a screenplay, treatment, scene list, essay, or chapter. \
        Segment it into ordered structural UNITS (scenes, beats, or paragraphs — chunk at the \
        natural structural grain, usually 6–30 units). For EACH unit, name the dramatic or \
        rhetorical JOB it performs as a VERB phrase ("retarde la révélation", "ré-énonce la \
        blessure", "ne fait rien"), classify its type, and rate its tension honestly.

        Then step back and diagnose the STRUCTURE as a whole — the holes the writer's eye \
        glosses over:
        - Several units doing the SAME job (redundancy) — mark them `repeat` and name the cluster in `holes`.
        - Flat stretches with no turn (dramatically dead zones).
        - A reveal that lands too early, or a climax with no setup.
        - A missing turn between the setup and the climax.

        Rules:
        - Read for STRUCTURE, not content. The `function` must be a verb phrase about the work, \
        never a plot summary.
        - Be honest. If three scenes do the same thing, say so. If a stretch is dead, give it low \
        tension. Do not invent problems that aren't there — return an empty `holes` array if the \
        structure is sound.
        - `sourceQuote` must be copied VERBATIM from the document (a short, distinctive snippet) so \
        the app can locate the passage.
        - `tension` must reflect real dramatic pressure, not your politeness. Flat means flat.
        - Return ONLY the structured tool call. No prose.
        """
    }

    private func userPrompt(french: Bool, document: String) -> String {
        let head = french
            ? "Radiographie ce texte. Montre-moi son squelette : ce que chaque unité FAIT, et les trous de structure."
            : "X-ray this text. Show me its skeleton: what each unit DOES, and the structural holes."
        return "\(head)\n\n----- DOCUMENT -----\n\(document)\n----- FIN -----"
    }

    private static func errorMessage(from data: Data) -> String {
        if let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = root["error"] as? [String: Any],
           let message = error["message"] as? String {
            return message
        }
        return String(data: data, encoding: .utf8) ?? t("erreur inconnue", "unknown error")
    }
}
