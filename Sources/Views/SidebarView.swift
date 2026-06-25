import SwiftUI
import SwiftData

/// The library sidebar: saved radiographs, newest first. Click to reopen on the
/// table. A "Nouveau" action clears the table for a fresh document.
struct SidebarView: View {
    @EnvironmentObject private var workbench: Workbench
    @Environment(\.modelContext) private var context
    @Query(sort: \XRay.updatedAt, order: .reverse) private var xrays: [XRay]

    @State private var pendingDelete: XRay?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "skew").foregroundStyle(Theme.blueprint)
                Text("L'Envers").font(Theme.serif(15, .semibold)).foregroundStyle(Theme.ink)
            }
            .padding(.horizontal, 14).padding(.top, 14).padding(.bottom, 8)

            Button {
                workbench.newDocument()
            } label: {
                Label(t("Nouveau texte", "New Text"), systemImage: "plus")
                    .font(.system(size: 12, weight: .medium))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6).padding(.horizontal, 10)
                    .background(Theme.blueprintFaint, in: RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)

            Text(t("RADIOGRAPHIES", "X-RAYS"))
                .font(Theme.mono(9, .semibold))
                .foregroundStyle(Theme.inkFaint)
                .padding(.horizontal, 16).padding(.top, 14).padding(.bottom, 4)

            if xrays.isEmpty {
                Text(t("Aucune radiographie enregistrée.", "No saved X-rays yet."))
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.inkFaint)
                    .padding(.horizontal, 16).padding(.top, 6)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(xrays) { xray in
                            row(xray)
                        }
                    }
                    .padding(.horizontal, 8)
                }
            }
        }
        .frame(minWidth: 220)
        .background(Theme.paperSunken)
        .confirmationDialog(t("Supprimer cette radiographie ?", "Delete this X-ray?"),
                            isPresented: Binding(get: { pendingDelete != nil },
                                                 set: { if !$0 { pendingDelete = nil } }),
                            presenting: pendingDelete) { xray in
            Button(t("Supprimer", "Delete"), role: .destructive) {
                if workbench.boundXRayID == xray.persistentModelID {
                    workbench.newDocument()
                }
                context.delete(xray)
                try? context.save()
                pendingDelete = nil
            }
            Button(t("Annuler", "Cancel"), role: .cancel) { pendingDelete = nil }
        } message: { xray in
            Text(xray.title)
        }
    }

    private func row(_ xray: XRay) -> some View {
        let isCurrent = workbench.boundXRayID == xray.persistentModelID
        return Button {
            workbench.open(xray)
        } label: {
            VStack(alignment: .leading, spacing: 3) {
                Text(xray.title)
                    .font(Theme.serif(13, .medium))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(xray.createdAt, style: .date)
                        .font(Theme.mono(9))
                        .foregroundStyle(Theme.inkFaint)
                    Text("· \(xray.units.count)u")
                        .font(Theme.mono(9))
                        .foregroundStyle(Theme.blueprintDim)
                    if !xray.holes.isEmpty {
                        Text("· \(xray.holes.count)✕")
                            .font(Theme.mono(9))
                            .foregroundStyle(Theme.oxbloodDim)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 7).padding(.horizontal, 9)
            .background(isCurrent ? Theme.blueprintFaint : Color.clear,
                        in: RoundedRectangle(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(t("Ouvrir", "Open")) { workbench.open(xray) }
            Button(t("Supprimer", "Delete"), role: .destructive) { pendingDelete = xray }
        }
    }
}
