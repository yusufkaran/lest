import SwiftUI

/// Adds a note by hand: type, pick the project, press Return.
struct AddNoteBar: View {
    let projects: [String]
    @Binding var project: String
    let presentation: PanelPresentation
    let onAdd: (_ text: String, _ project: String) -> Void

    @State private var text = ""
    @FocusState private var focus: AddNoteField?

    private var canSubmit: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        HStack(spacing: Theme.rowPadding) {
            PhosphorIcon(.plusBold, size: Theme.smallIconSize)
                .foregroundStyle(.secondary)
            TextField("New note…", text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .focused($focus, equals: .note)
                .onSubmit(submit)
            ProjectChooser(projects: projects, project: $project, focus: $focus)
            Button(action: submit) {
                PhosphorIcon(.arrowUpBold, size: Theme.smallIconSize)
                    .foregroundStyle(canSubmit ? AnyShapeStyle(.white) : AnyShapeStyle(.secondary))
                    .frame(width: Theme.sendButtonSize, height: Theme.sendButtonSize)
                    .background(canSubmit ? AnyShapeStyle(Theme.accent) : AnyShapeStyle(.quaternary), in: .circle)
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit)
            .accessibilityLabel("Add note")
        }
        .padding(.leading, Theme.padding)
        .padding(.trailing, Theme.rowPadding)
        .padding(.vertical, Theme.rowPadding)
        .background(.quinary, in: .rect(cornerRadius: Theme.cardRadius))
        .onChange(of: presentation.count) { focusNote() }
    }

    /// Opening the panel should be enough to start typing a note.
    private func focusNote() {
        focus = .note
    }

    private func submit() {
        onAdd(text, project)
        text = ""
        focus = .note
    }
}
