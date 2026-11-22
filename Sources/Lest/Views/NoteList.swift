import SwiftUI
import LestCore

/// The notes, one card per project. The panel grows with the list up to a limit, then scrolls.
struct NoteList: View {
    let groups: [ProjectGroup]
    let showsDone: Bool
    let hasAnyNotes: Bool
    let model: AppModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if groups.isEmpty {
            EmptyState(hasAnyNotes: hasAnyNotes)
        } else {
            ScrollView {
                VStack(spacing: Theme.cardSpacing) {
                    ForEach(groups) { group in
                        ProjectSection(group: group, showsDone: showsDone, model: model)
                    }
                }
                .padding(.horizontal, Theme.padding)
                .animation(reduceMotion ? nil : Theme.animation, value: groups)
            }
            .scrollIndicators(.never)
            .frame(maxHeight: Theme.listMaxHeight)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}
