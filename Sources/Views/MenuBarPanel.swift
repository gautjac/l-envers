import SwiftUI

/// The quick-summon menu bar panel. Small by design: it surfaces the current
/// document's status and a button to bring the editor window forward.
struct MenuBarPanel: View {
    @EnvironmentObject private var workbench: Workbench
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "skew").foregroundStyle(Theme.blueprint)
                Text("L'Envers").font(Theme.serif(15, .semibold)).foregroundStyle(Theme.ink)
                Spacer()
            }

            if workbench.hasRadiograph {
                VStack(alignment: .leading, spacing: 4) {
                    Text(workbench.title.isEmpty ? t("Sans titre", "Untitled") : workbench.title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Theme.ink)
                        .lineLimit(1)
                    Text(t("\(workbench.units.count) unités · \(workbench.holes.count) trous",
                           "\(workbench.units.count) units · \(workbench.holes.count) holes"))
                        .font(Theme.mono(11))
                        .foregroundStyle(Theme.inkDim)
                }
            } else {
                Text(t("Aucune radiographie en cours.", "No X-ray in progress."))
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.inkDim)
            }

            Divider().overlay(Theme.paperEdge)

            Button {
                NSApp.activate(ignoringOtherApps: true)
                bringWindowForward()
            } label: {
                Label(t("Ouvrir L'Envers", "Open L'Envers"), systemImage: "macwindow")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)

            Button {
                NSApp.activate(ignoringOtherApps: true)
                bringWindowForward()
                Task { await workbench.radiograph() }
            } label: {
                Label(t("Radiographier", "X-ray"), systemImage: "waveform.path.ecg")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .disabled(workbench.sourceText.isEmpty || workbench.phase == .analyzing)
        }
        .padding(14)
        .frame(width: 240)
    }

    private func bringWindowForward() {
        // Raise the main editor window if it exists.
        for window in NSApp.windows where window.canBecomeMain {
            window.makeKeyAndOrderFront(nil)
            return
        }
    }
}
