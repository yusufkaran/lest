import SwiftUI
import LestCore

struct ProjectHeader: View {
    let group: ProjectGroup

    var body: some View {
        HStack(spacing: Theme.itemSpacing) {
            ProjectTile(name: group.name)
            Text(group.name)
                .font(.headline)
                .lineLimit(1)
            Spacer(minLength: 0)
            Text(group.open.count, format: .number)
                .font(.subheadline)
                .bold()
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .padding(.horizontal, Theme.rowPadding)
                .padding(.vertical, Theme.textSpacing)
                .background(.quaternary, in: .capsule)
                .accessibilityLabel(openNotesLabel(group.open.count))
        }
        .padding(Theme.rowPadding)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
        .contextMenu {
            Button("Open Folder in Finder", action: openFolder)
                .disabled(group.path == nil)
        }
    }

    private func openFolder() {
        guard let path = group.path else { return }
        NSWorkspace.shared.open(URL(filePath: path, directoryHint: .isDirectory))
    }
}
