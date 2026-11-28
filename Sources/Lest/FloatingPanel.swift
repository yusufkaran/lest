import AppKit

/// The window behind the notes panel: no title bar or frame of its own, so the panel's
/// rounded shape is all there is. It floats above other apps and takes the keyboard without
/// bringing this app to the front.
final class FloatingPanel: NSPanel {
    /// Called when the user presses Escape.
    var onCancel: () -> Void = {}

    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        level = .statusBar
        collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary, .transient]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        hidesOnDeactivate = false
        isMovable = false
    }

    /// A borderless window refuses the keyboard unless told otherwise, and notes are typed here.
    override var canBecomeKey: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        onCancel()
    }

    /// With no text field focused, as on the completed notes page, Escape arrives here as a
    /// plain key press instead of a cancel command.
    override func keyDown(with event: NSEvent) {
        if event.keyCode == Self.escapeKeyCode {
            onCancel()
        } else {
            super.keyDown(with: event)
        }
    }

    private static let escapeKeyCode: UInt16 = 53
}
