import SwiftUI
import LestCore

/// Picks the project a hand-written note goes to, or names a new one.
struct ProjectChooser: View {
    let projects: [String]
    @Binding var project: String
    var focus: FocusState<AddNoteField?>.Binding

    @State private var isNaming = false
    @State private var newName = ""

    /// Known projects, plus the selected one when it has no notes yet.
    private var choices: [String] {
        var names = projects
        for name in [project, Note.defaultProject] where !names.contains(name) {
            names.append(name)
        }
        return names
    }

    var body: some View {
        if isNaming {
            TextField("Project name", text: $newName)
                .textFieldStyle(.plain)
                .font(.callout)
                .padding(.horizontal, Theme.itemSpacing)
                .padding(.vertical, Theme.chipSpacing)
                .frame(width: Theme.projectFieldWidth)
                .background(.quaternary, in: .capsule)
                .focused(focus, equals: .projectName)
                .onSubmit(finishNaming)
                .onAppear(perform: focusName)
                .onChange(of: focus.wrappedValue) { useNameWhenFocusLeaves() }
        } else {
            Menu {
                Picker("Project", selection: $project) {
                    ForEach(choices, id: \.self) { name in
                        Text(name)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
                Divider()
                Button("New Project…", action: startNaming)
            } label: {
                HStack(spacing: Theme.chipSpacing) {
                    Circle()
                        .fill(Theme.color(forProject: project))
                        .frame(width: Theme.dotSize, height: Theme.dotSize)
                    Text(project)
                        .lineLimit(1)
                    PhosphorIcon(.caretDownBold, size: Theme.dotSize + 2)
                        .foregroundStyle(.secondary)
                }
                .font(.callout)
                .padding(.horizontal, Theme.itemSpacing)
                .padding(.vertical, Theme.chipSpacing)
                .frame(maxWidth: Theme.projectFieldWidth)
                .contentShape(.capsule)
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .background(.quaternary, in: .capsule)
            .fixedSize()
            .accessibilityLabel("Project: \(project)")
        }
    }

    private func startNaming() {
        newName = ""
        isNaming = true
    }

    private func focusName() {
        focus.wrappedValue = .projectName
    }

    private func finishNaming() {
        useName()
        focus.wrappedValue = .note
    }

    /// Clicking into the note field after typing a name means the name is wanted, even
    /// without pressing Return.
    private func useNameWhenFocusLeaves() {
        if focus.wrappedValue != .projectName { useName() }
    }

    private func useName() {
        let name = newName.trimmingCharacters(in: .whitespaces)
        if !name.isEmpty { project = name }
        isNaming = false
    }
}
