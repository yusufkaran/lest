import SwiftUI
import LestCore

struct NoteRow: View {
    let note: Note
    let model: AppModel

    @State private var isHovered = false

    private var toggleTitle: String { note.isDone ? "Reopen" : "Mark as Done" }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: Theme.itemSpacing) {
            Button(action: toggle) {
                PhosphorIcon(note.isDone ? .checkCircleFill : .circle, size: Theme.checkboxSize)
                    .contentShape(.circle)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Theme.color(forProject: note.project).opacity(note.isDone ? 0.55 : 1))
            .alignmentGuide(.firstTextBaseline) { $0[.bottom] - Theme.checkboxBaselineOffset }
            .accessibilityLabel(toggleTitle)

            VStack(alignment: .leading, spacing: Theme.textSpacing) {
                Text(note.text)
                    .strikethrough(note.isDone)
                    .foregroundStyle(note.isDone ? .secondary : .primary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(note.createdAt, format: .relative(presentation: .named))
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
            Button(toggleTitle, action: toggle)
            Button("Copy", action: copy)
            Divider()
            Button("Delete", role: .destructive, action: delete)
        }
    }

    private func toggle() {
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
