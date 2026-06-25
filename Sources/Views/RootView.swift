import SwiftUI
import SwiftData

/// The drafting table: a three-column workbench — library sidebar, source pane,
/// the spine X-ray — with the holes panel as a fourth, collapsible column. The
/// toolbar carries the two verbs that matter: Radiographier and Enregistrer.
struct RootView: View {
    @EnvironmentObject private var workbench: Workbench
    @Environment(\.modelContext) private var context
    @AppStorage("lenvers.onboarded.v1") private var onboarded = false

    @State private var showHoles = true

    var body: some View {
        Group {
            if onboarded {
                workbenchBody
            } else {
                OnboardingView { withAnimation { onboarded = true } }
            }
        }
    }

    private var workbenchBody: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            HSplitView {
                SourcePane()
                    .frame(minWidth: 300)
                SpineView()
                    .frame(minWidth: 340)
                if showHoles && workbench.hasRadiograph {
                    HolesPanel()
                        .frame(minWidth: 240, maxWidth: 340)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    workbench.openFile()
                } label: {
                    Label(t("Ouvrir", "Open"), systemImage: "folder")
                }
                .help(t("Ouvrir un .txt, .md ou .fountain", "Open a .txt, .md or .fountain"))

                Button {
                    Task { await workbench.radiograph() }
                } label: {
                    Label(t("Radiographier", "X-ray"), systemImage: "waveform.path.ecg")
                }
                .help(t("Révéler le squelette du texte", "Reveal the text's skeleton"))
                .disabled(workbench.sourceText.isEmpty || workbench.phase == .analyzing)

                Button {
                    workbench.save(into: context)
                } label: {
                    Label(t("Enregistrer", "Save"), systemImage: "tray.and.arrow.down")
                }
                .help(t("Enregistrer cette radiographie", "Save this X-ray"))
                .disabled(!workbench.hasRadiograph)

                if workbench.hasRadiograph {
                    Toggle(isOn: $showHoles) {
                        Label(t("Trous", "Holes"), systemImage: "stethoscope")
                    }
                    .help(t("Afficher le panneau des trous", "Show the holes panel"))
                }
            }
        }
        .navigationTitle("L'Envers")
    }
}
