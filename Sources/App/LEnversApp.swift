import SwiftUI
import SwiftData
import AppKit

/// L'Envers — a macOS reverse-outliner / "story X-ray".
///
/// A real windowed app (`WindowGroup`) with a big drafting canvas, plus a
/// `MenuBarExtra` for quick summon. Documents and their radiographs persist
/// locally with SwiftData. The app calls Anthropic directly with the user's
/// own key (stored in the Keychain) — no backend.
@main
struct LEnversApp: App {
    /// One workbench per app session (the window edits the current document).
    @StateObject private var workbench = Workbench()
    @AppStorage("lenvers.onboarded.v1") private var onboarded = false

    /// The local SwiftData store for saved radiographs.
    let container: ModelContainer = {
        let schema = Schema([XRay.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            // Last-resort in-memory store so the app still launches if the
            // on-disk store is unreadable.
            let mem = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: [mem])
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(workbench)
                .frame(minWidth: 1040, minHeight: 680)
                .background(Theme.paper)
                .preferredColorScheme(.light)
        }
        .modelContainer(container)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            CommandGroup(replacing: .newItem) {
                Button(t("Nouveau texte", "New Text")) { workbench.newDocument() }
                    .keyboardShortcut("n", modifiers: .command)
                Button(t("Ouvrir un fichier…", "Open File…")) { workbench.openFile() }
                    .keyboardShortcut("o", modifiers: .command)
            }
            CommandGroup(after: .textEditing) {
                Button(t("Radiographier", "X-ray")) {
                    Task { await workbench.radiograph() }
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(workbench.phase == .analyzing || workbench.sourceText.isEmpty)
            }
        }

        // Quick-summon menu bar item — clicking it brings the editor forward.
        MenuBarExtra {
            MenuBarPanel()
                .environmentObject(workbench)
        } label: {
            Image(systemName: "skew")
                .accessibilityLabel("L'Envers")
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .frame(width: 460)
        }
    }
}
