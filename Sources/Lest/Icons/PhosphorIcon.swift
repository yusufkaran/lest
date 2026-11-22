import SwiftUI

/// A Phosphor icon drawn in the current foreground style. It is decorative: buttons that
/// show only an icon carry their name in an accessibility label.
struct PhosphorIcon: View {
    private let icon: Phosphor
    private let size: Double

    init(_ icon: Phosphor, size: Double = Theme.iconSize) {
        self.icon = icon
        self.size = size
    }

    var body: some View {
        Image(nsImage: icon.image(pointSize: size))
            .renderingMode(.template)
            .accessibilityHidden(true)
    }
}
