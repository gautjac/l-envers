import SwiftUI

/// Réglages: paste the Anthropic API key (stored in the Keychain, never in
/// UserDefaults). Calm, FR-first, with a friendly empty state.
struct SettingsView: View {
    @State private var draftKey: String = ""
    @State private var hasKey: Bool = Keychain.hasAPIKey
    @State private var savedFlash = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Image(systemName: "key.viewfinder")
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.blueprint)
                VStack(alignment: .leading, spacing: 2) {
                    Text(t("Clé API Anthropic", "Anthropic API Key"))
                        .font(Theme.serif(17, .semibold))
                        .foregroundStyle(Theme.ink)
                    Text(t("Ta clé reste sur cet ordi, dans le Trousseau.",
                           "Your key stays on this Mac, in the Keychain."))
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.inkDim)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                SecureField(t("colle ta clé sk-ant-…", "paste your key sk-ant-…"), text: $draftKey)
                    .textFieldStyle(.roundedBorder)
                    .font(Theme.mono(12))

                HStack {
                    Button {
                        _ = Keychain.setAPIKey(draftKey)
                        hasKey = Keychain.hasAPIKey
                        draftKey = ""
                        withAnimation { savedFlash = true }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                            withAnimation { savedFlash = false }
                        }
                    } label: {
                        Text(t("Enregistrer", "Save")).frame(minWidth: 90)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.blueprint)
                    .disabled(draftKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                    if hasKey {
                        Button(role: .destructive) {
                            Keychain.deleteAPIKey()
                            hasKey = Keychain.hasAPIKey
                        } label: {
                            Text(t("Oublier la clé", "Forget Key"))
                        }
                        .buttonStyle(.bordered)
                    }
                    Spacer()
                    if savedFlash {
                        Label(t("Enregistrée", "Saved"), systemImage: "checkmark.circle.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(red: 0.255, green: 0.522, blue: 0.420))
                            .transition(.opacity)
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: hasKey ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                        .foregroundStyle(hasKey ? Theme.blueprint : Theme.ochre)
                    Text(hasKey
                         ? t("Une clé est en place. L'Envers peut radiographier.",
                             "A key is set. L'Envers can X-ray.")
                         : t("Aucune clé. Colle-la ci-dessus pour activer la radiographie.",
                             "No key yet. Paste one above to enable X-rays."))
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.inkDim)
                }
                .padding(.top, 2)
            }

            Divider().overlay(Theme.paperEdge)

            VStack(alignment: .leading, spacing: 6) {
                Text(t("Comment obtenir une clé", "How to get a key"))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Theme.ink)
                Text(t("Crée une clé sur console.anthropic.com → Settings → API Keys. Le modèle utilisé est claude-opus-4-8.",
                       "Create a key at console.anthropic.com → Settings → API Keys. The model used is claude-opus-4-8."))
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.inkDim)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(22)
        .background(Theme.paper)
    }
}
