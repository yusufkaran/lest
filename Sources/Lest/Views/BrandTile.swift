import SwiftUI

/// The app's mark, matching the app icon.
struct BrandTile: View {
    var body: some View {
        PhosphorIcon(.listChecksBold, size: Theme.menuBarIconSize)
            .foregroundStyle(.white)
            .frame(width: Theme.brandTileSize, height: Theme.brandTileSize)
            .background(Theme.brandGradient, in: .rect(cornerRadius: Theme.controlRadius))
    }
}
