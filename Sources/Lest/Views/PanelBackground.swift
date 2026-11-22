import SwiftUI

/// The rounded, frosted backdrop of the panel: a blur of whatever is behind the window, as in
/// the system's own menus and popovers.
struct PanelBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .popover
        view.blendingMode = .behindWindow
        view.state = .active
        // The mask rounds the blur and, because the window is otherwise transparent, also
        // gives the window and its shadow their shape.
        view.maskImage = Self.roundedMask
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {}

    /// A rounded square that stretches from its middle, so the corners keep their radius at
    /// any panel size.
    private static var roundedMask: NSImage {
        let radius = Theme.panelRadius
        let side = radius * 2 + 1
        let image = NSImage(size: NSSize(width: side, height: side), flipped: false) { rect in
            NSColor.black.setFill()
            NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius).fill()
            return true
        }
        image.capInsets = NSEdgeInsets(top: radius, left: radius, bottom: radius, right: radius)
        image.resizingMode = .stretch
        return image
    }
}
