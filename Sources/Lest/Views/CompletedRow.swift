import SwiftUI
import LestCore

/// A completed note, with its project and the time it was completed.
struct CompletedRow: View {
    let note: Note
    let model: AppModel

    @State private var isHovered = false

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.itemSpacing) {
            Button(action: reopen) {
                PhosphorIcon(.checkCircleFill, size: Theme.checkboxSize)
                    .contentShape(.circle)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.color(forProject: note.project))
            .alignmentGuide(.firstTextBaseline) { $0[.bottom] - Theme.checkboxBaselineOffset }
            .help("Reopen")
            .accessibilityLabel("Reopen")

            VStack(alignment: .leading, spacing: Theme.textSpacing) {
                Text(note.text)
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: Theme.chipSpacing) {
                    Circle()
                        .fill(Theme.color(forProject: note.project))
                        .frame(width: Theme.dotSize, height: Theme.dotSize)
                    Text(note.project)
                        .lineLimit(1)
                    if let doneAt = note.doneAt {
                        Text("·")
                        Text(doneAt, format: .dateTime.hour().minute())
                            .monospacedDigit()
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.tertiary)
            }

            Spacer(minLength: 0)

            Button(action: delete) {
                PhosphorIcon(.trash)
                    .frame(width: Theme.checkboxSize, height: Theme.checkboxSize)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .opacity(isHovered ? 1 : 0)
            .alignmentGuide(.firstTextBaseline) { $0[.bottom] - Theme.checkboxBaselineOffset }
            .accessibilityLabel("Delete")
        }
        .padding(Theme.rowPadding)
        .background(.quaternary.opacity(isHovered ? 1 : 0), in: .rect(cornerRadius: Theme.rowRadius))
        .onHover { isHovered = $0 }
        .contextMenu {
            Button("Reopen", action: reopen)
            Button("Copy", action: copy)
            Divider()
            Button("Delete", role: .destructive, action: delete)
        }
    }

    private func reopen() {
        model.toggle(note)
    }

    private func delete() {
        model.delete(note)
    }

    private func copy() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(note.text, forType: .string)
    }
}
