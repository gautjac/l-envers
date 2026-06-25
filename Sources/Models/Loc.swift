import Foundation

/// L'Envers is FR-first (Québécois). The whole UI is authored in French; this
/// tiny helper lets a few strings fall back to English if the system is set to
/// English. Kept deliberately minimal — no .strings files to manage.
@inline(__always)
func t(_ fr: String, _ en: String) -> String {
    let pref = Locale.preferredLanguages.first ?? "fr"
    return pref.hasPrefix("fr") ? fr : en
}

/// Whether the current locale leans French (for prompts sent to the model).
var prefersFrench: Bool {
    (Locale.preferredLanguages.first ?? "fr").hasPrefix("fr")
}
