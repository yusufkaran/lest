import SwiftUI

/// Gives the panel its soft, rounded shape. The window itself draws nothing, so this backdrop
/// and its hairline edge are the whole outline of the panel.
struct PanelChrome: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background { PanelBackground() }
            .overlay {
                // Circular corners to match the backdrop's mask exactly.
                RoundedRectangle(cornerRadius: Theme.panelRadius, style: .circular)
                    .strokeBorder(.separator)
                    .allowsHitTesting(false)
            }
    }
}
