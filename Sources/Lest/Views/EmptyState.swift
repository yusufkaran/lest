import SwiftUI

struct EmptyState: View {
    /// Whether the list is empty only because every note is done or filtered out.
    let hasAnyNotes: Bool

    var body: some View {
        VStack(spacing: Theme.itemSpacing) {
            PhosphorIcon(hasAnyNotes ? .checkCircleDuotone : .notePencilDuotone, size: Theme.emptyTileSize / 2)
                .foregroundStyle(Theme.accent)
                .frame(width: Theme.emptyTileSize, height: Theme.emptyTileSize)
                .background(Theme.accent.opacity(0.15), in: .rect(cornerRadius: Theme.cardRadius))
            Text(hasAnyNotes ? "No open notes" : "No notes yet")
                .font(.headline)
            Text("Tell your coding agent “add this to my to-do list”, or write one below.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Theme.padding * 3)
        .padding(.vertical, Theme.padding * 2)
        .accessibilityElement(children: .combine)
    }
}
