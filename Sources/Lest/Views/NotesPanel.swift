import SwiftUI
import LestCore

/// The window that opens under the menu bar item: the open notes, or the completed ones on a
/// page of their own.
struct NotesPanel: View {
    let model: AppModel
    let loginItem: LoginItem
    let presentation: PanelPresentation

    @AppStorage("targetProject") private var targetProject = Note.defaultProject
    @State private var filter: String?

    /// Projects with open notes. Completed notes stay off this page.
    private var listedGroups: [ProjectGroup] {
        model.groups.filter { !$0.open.isEmpty }
    }

    private var visibleGroups: [ProjectGroup] {
        listedGroups.filter { filter == nil || $0.name == filter }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.blockSpacing) {
            if presentation.showsCompleted {
                completedPage
            } else {
                notesPage
            }
        }
        .padding(.vertical, Theme.padding)
        .frame(width: Theme.panelWidth)
        .fontDesign(.rounded)
        .environment(\.locale, Locale(identifier: "en"))
        .onChange(of: loginItem.isEnabled) { loginItem.apply() }
        .onChange(of: filter) { addToFilteredProject() }
        .onChange(of: listedGroups.map(\.name)) { clearFilterIfProjectIsGone() }
    }

    @ViewBuilder private var notesPage: some View {
        PanelHeader(model: model, loginItem: loginItem, onShowCompleted: showCompleted)
            .padding(.horizontal, Theme.padding)
        if listedGroups.count > 1 {
            ProjectFilterBar(groups: listedGroups, filter: $filter)
        }
        errorBanner
        NoteList(groups: visibleGroups, hasAnyNotes: !model.groups.isEmpty, model: model)
        AddNoteBar(
            projects: model.projectNames,
            project: $targetProject,
            presentation: presentation,
            onAdd: model.add
        )
        .padding(.horizontal, Theme.padding)
    }

    @ViewBuilder private var completedPage: some View {
        CompletedHeader(count: model.doneCount, onBack: showOpenNotes)
            .padding(.horizontal, Theme.padding)
        errorBanner
        CompletedList(days: model.completedDays, model: model)
    }

    @ViewBuilder private var errorBanner: some View {
        if let message = model.errorMessage ?? loginItem.errorMessage {
            ErrorBanner(message: message)
                .padding(.horizontal, Theme.padding)
        }
    }

    private func showCompleted() {
        presentation.showsCompleted = true
    }

    private func showOpenNotes() {
        presentation.showsCompleted = false
    }

    /// While looking at one project, new notes should land in it.
    private func addToFilteredProject() {
        if let filter { targetProject = filter }
    }

    private func clearFilterIfProjectIsGone() {
        if let filter, !listedGroups.contains(where: { $0.name == filter }) { self.filter = nil }
    }
}
