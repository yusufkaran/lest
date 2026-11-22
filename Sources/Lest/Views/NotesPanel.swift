import SwiftUI
import LestCore

/// The window that opens under the menu bar item.
struct NotesPanel: View {
    let model: AppModel
    let loginItem: LoginItem
    let presentation: PanelPresentation

    @AppStorage("showsDone") private var showsDone = false
    @AppStorage("targetProject") private var targetProject = Note.defaultProject
    @State private var filter: String?

    /// Projects that have something to show with the current "show done notes" setting.
    private var listedGroups: [ProjectGroup] {
        model.groups.filter { showsDone || !$0.open.isEmpty }
    }

    private var visibleGroups: [ProjectGroup] {
        listedGroups.filter { filter == nil || $0.name == filter }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.blockSpacing) {
            PanelHeader(model: model, loginItem: loginItem, showsDone: $showsDone)
                .padding(.horizontal, Theme.padding)
            if listedGroups.count > 1 {
                ProjectFilterBar(groups: listedGroups, filter: $filter)
            }
            if let message = model.errorMessage ?? loginItem.errorMessage {
                ErrorBanner(message: message)
                    .padding(.horizontal, Theme.padding)
            }
            NoteList(groups: visibleGroups, showsDone: showsDone, hasAnyNotes: !model.groups.isEmpty, model: model)
            AddNoteBar(
                projects: model.projectNames,
                project: $targetProject,
                presentation: presentation,
                onAdd: model.add
            )
            .padding(.horizontal, Theme.padding)
        }
        .padding(.vertical, Theme.padding)
        .frame(width: Theme.panelWidth)
        .fontDesign(.rounded)
        .environment(\.locale, Locale(identifier: "en"))
        .onChange(of: loginItem.isEnabled) { loginItem.apply() }
        .onChange(of: filter) { addToFilteredProject() }
        .onChange(of: listedGroups.map(\.name)) { clearFilterIfProjectIsGone() }
    }

    /// While looking at one project, new notes should land in it.
    private func addToFilteredProject() {
        if let filter { targetProject = filter }
    }

    private func clearFilterIfProjectIsGone() {
        if let filter, !listedGroups.contains(where: { $0.name == filter }) { self.filter = nil }
    }
}
