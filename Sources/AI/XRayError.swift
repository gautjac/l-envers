import Foundation

/// Calm FR-first errors for the radiograph flow. Mirrors Pareidolia's `VisionError`.
enum XRayError: LocalizedError {
    case missingKey
    case emptyDocument
    case http(status: Int, message: String)
    case noToolUse
    case decoding(String)
    case transport(String)

    var errorDescription: String? {
        switch self {
        case .missingKey:
            return t("Aucune clé API. Ajoute-la dans les Réglages pour radiographier ton texte.",
                     "No API key. Add one in Settings to X-ray your text.")
        case .emptyDocument:
            return t("Il n'y a rien à radiographier — colle ou ouvre d'abord un texte.",
                     "Nothing to X-ray — paste or open a text first.")
        case .http(let status, let message):
            return t("Erreur \(status) : \(message)", "Error \(status): \(message)")
        case .noToolUse:
            return t("La radiographie n'a rien renvoyé de lisible. Réessaie.",
                     "The X-ray returned nothing readable. Try again.")
        case .decoding(let detail):
            return t("Lecture impossible : \(detail)", "Could not read the result: \(detail)")
        case .transport(let detail):
            return t("Réseau : \(detail)", "Network: \(detail)")
        }
    }
}
