import SwiftUI

/// Top of the completed notes page, with the way back to the open notes.
struct CompletedHeader: View {
    let count: Int
    let onBack: () -> Void

    private var summary: String {
        count == 1 ? "1 note" : "\(count) notes"
    }

    var body: some View {
        HStack(spacing: Theme.itemSpacing) {
            Button(action: onBack) {
                PhosphorIcon(.caretLeftBold, size: Theme.iconSize)
                    .frame(width: Theme.brandTileSize, height: Theme.brandTileSize)
                    .background(.quaternary, in: .rect(cornerRadius: Theme.controlRadius))
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .help("Back to open notes")
            .accessibilityLabel("Back to open notes")

            VStack(alignment: .leading, spacing: 0) {
                Text("Completed")
                    .font(.title3)
                    .bold()
                Text(summary)
                    .font(.callout)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
            Spacer()
        }
    }
}
