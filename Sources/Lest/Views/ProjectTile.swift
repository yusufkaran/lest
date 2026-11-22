import SwiftUI

/// A small colored square with the project's first letter, like a workspace avatar.
struct ProjectTile: View {
    let name: String

    var body: some View {
        Text(name.prefix(1).uppercased())
            .font(.subheadline)
            .bold()
            .foregroundStyle(.white)
            .frame(width: Theme.tileSize, height: Theme.tileSize)
            .background(Theme.color(forProject: name).gradient, in: .rect(cornerRadius: Theme.tileRadius))
            .accessibilityHidden(true)
    }
}
