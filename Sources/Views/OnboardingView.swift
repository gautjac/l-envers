import SwiftUI

/// Light, skippable first-run explainer: what an "envers" is, paste-or-open,
/// radiographier. Calm drafting-table register.
struct OnboardingView: View {
    let onDismiss: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Theme.paper.ignoresSafeArea()
            DraftingGrid().opacity(0.6)

            VStack(spacing: 22) {
                Spacer()

                Image(systemName: "skew")
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(Theme.blueprint)

                Text("L'Envers")
                    .font(Theme.serif(34, .semibold))
                    .foregroundStyle(Theme.ink)

                Text(t("La radiographie de ton récit.", "The X-ray of your story."))
                    .font(Theme.serif(16))
                    .italic()
                    .foregroundStyle(Theme.inkDim)

                VStack(alignment: .leading, spacing: 16) {
                    step(num: "1", title: t("L'envers du texte", "The underside of the text"),
                         body: t("L'Envers ne lit pas ce que ton texte DIT — il révèle ce que chaque scène FAIT. Le squelette caché que ton œil ne voit plus.",
                                 "L'Envers doesn't read what your text SAYS — it reveals what each scene DOES. The hidden skeleton your eye no longer sees."))
                    step(num: "2", title: t("Colle ou ouvre", "Paste or open"),
                         body: t("Un scénario, un traitement, une liste de scènes, un essai. Glisse-le ou ouvre un .txt, .md, .fountain.",
                                 "A screenplay, treatment, scene list, essay. Paste it or open a .txt, .md, .fountain."))
                    step(num: "3", title: t("Radiographier", "X-ray"),
                         body: t("Claude découpe ton texte en unités, nomme le travail de chacune, trace la tension et débusque les trous : trois scènes qui font la même job, une zone plate, une révélation trop tôt.",
                                 "Claude segments your text into units, names each one's job, traces the tension, and finds the holes: three scenes doing the same job, a flat stretch, a reveal too early."))
                }
                .frame(maxWidth: 520)
                .padding(.vertical, 8)

                Spacer()

                Button(action: onDismiss) {
                    Text(t("Sur la table à dessin", "Onto the drafting table"))
                        .font(.system(size: 14, weight: .semibold))
                        .frame(minWidth: 220)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.blueprint)

                Text(t("Tu auras besoin d'une clé API Anthropic (Réglages).",
                       "You'll need an Anthropic API key (Settings)."))
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.inkFaint)
                    .padding(.bottom, 12)
            }
            .padding(40)
        }
    }

    private func step(num: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(num)
                .font(Theme.mono(15, .bold))
                .foregroundStyle(Theme.paper)
                .frame(width: 30, height: 30)
                .background(Theme.blueprint, in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(Theme.serif(15, .semibold))
                    .foregroundStyle(Theme.ink)
                Text(body)
                    .font(.system(size: 12.5))
                    .foregroundStyle(Theme.inkDim)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
