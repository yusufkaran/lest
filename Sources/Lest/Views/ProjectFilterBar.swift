import SwiftUI
import LestCore

/// Chips that narrow the list to one project. They wrap onto more lines when the projects do
/// not fit on one, so every project stays one click away.
struct ProjectFilterBar: View {
    let groups: [ProjectGroup]
    @Binding var filter: String?

    private var openCount: Int { groups.reduce(0) { $0 + $1.open.count } }

    var body: some View {
        FlowLayout(spacing: Theme.chipSpacing) {
            FilterChip(title: "All", count: openCount, color: nil, project: nil, selection: $filter)
            ForEach(groups) { group in
                FilterChip(
                    title: group.name,
                    count: group.open.count,
                    color: Theme.color(forProject: group.name),
                    project: group.name,
                    selection: $filter
                )
            }
        }
        .padding(.horizontal, Theme.padding)
    }
}
