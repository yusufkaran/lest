import SwiftUI
import LestCore

/// One project's notes as a card.
struct ProjectSection: View {
    let group: ProjectGroup
    let showsDone: Bool
    let model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.textSpacing) {
            ProjectHeader(group: group)
            ForEach(group.open) { note in
                NoteRow(note: note, model: model)
            }
            if showsDone {
                ForEach(group.done) { note in
                    NoteRow(note: note, model: model)
                }
            }
        }
        .padding(Theme.cardPadding)
        .background(.quinary, in: .rect(cornerRadius: Theme.cardRadius))
    }
}
