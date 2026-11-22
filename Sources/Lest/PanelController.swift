import AppKit
import SwiftUI

/// Opens the notes panel under the menu bar item and closes it again when the user clicks
/// elsewhere, presses Escape, or clicks the item a second time.
@MainActor
final class PanelController: NSObject, NSWindowDelegate {
    private let panel = FloatingPanel()
    private let presentation = PanelPresentation()
    private var outsideClickMonitor: Any?
    private var topLeft = NSPoint.zero
    private var lastDismissal = Date.distantPast

    init(model: AppModel, loginItem: LoginItem) {
        super.init()
        let content = NotesPanel(model: model, loginItem: loginItem, presentation: presentation)
            .modifier(PanelChrome())
        panel.contentView = NSHostingView(rootView: content)
        panel.delegate = self
        panel.onCancel = { [weak self] in self?.hide() }
    }

    func toggle(below anchor: NSRect?) {
        if panel.isVisible {
            hide()
        } else if Date.now.timeIntervalSince(lastDismissal) > Theme.reopenDelay {
            // A click on the menu bar item while the panel is open is also a click outside the
            // panel, which has just closed it. Without the pause that same click would reopen it.
            show(below: anchor, takingFocus: true)
        }
    }

    func show(below anchor: NSRect?, takingFocus: Bool) {
        guard !panel.isVisible else { return }

        panel.layoutIfNeeded()
        topLeft = Self.topLeft(forPanelOfSize: panel.frame.size, below: anchor)
        panel.setFrameTopLeftPoint(topLeft)
        if takingFocus {
            panel.makeKeyAndOrderFront(nil)
            presentation.didShow()
        } else {
            panel.orderFrontRegardless()
        }
        panel.invalidateShadow()

        outsideClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) {
            [weak self] _ in
            MainActor.assumeIsolated { self?.hide() }
        }
    }

    func hide() {
        guard panel.isVisible else { return }

        panel.orderOut(nil)
        if let outsideClickMonitor { NSEvent.removeMonitor(outsideClickMonitor) }
        outsideClickMonitor = nil
        lastDismissal = .now
    }

    func windowDidResignKey(_ notification: Notification) {
        hide()
    }

    /// The panel grows and shrinks with the list. Its top edge has to stay under the menu bar,
    /// while a window resizes from its bottom-left corner.
    func windowDidResize(_ notification: Notification) {
        panel.setFrameTopLeftPoint(topLeft)
    }

    private static func topLeft(forPanelOfSize size: NSSize, below anchor: NSRect?) -> NSPoint {
        let screen = NSScreen.screens.first { screen in anchor.map(screen.frame.intersects) ?? false } ?? NSScreen.main
        guard let visible = screen?.visibleFrame else { return .zero }

        let leftmost = visible.minX + Theme.panelMargin
        let rightmost = visible.maxX - size.width - Theme.panelMargin
        guard let anchor else {
            return NSPoint(x: rightmost, y: visible.maxY - Theme.panelMargin)
        }
        let centered = anchor.midX - size.width / 2
        return NSPoint(x: min(max(centered, leftmost), rightmost), y: anchor.minY - Theme.panelMargin)
    }
}
