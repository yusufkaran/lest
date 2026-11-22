import AppKit
import Observation
import LestCore

/// The menu bar item: the icon, followed by the number of open notes when there are any.
/// Clicking it opens and closes the panel.
@MainActor
final class StatusItemController: NSObject {
    private let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let model: AppModel
    private let panel: PanelController

    init(model: AppModel, panel: PanelController) {
        self.model = model
        self.panel = panel
        super.init()

        if let button = item.button {
            button.image = Phosphor.listChecksBold.image(pointSize: Theme.menuBarIconSize)
            button.imagePosition = .imageLeading
            button.target = self
            button.action = #selector(togglePanel)
        }
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(showPanelWithoutFocus),
            name: AppSignal.showPanel,
            object: nil,
            suspensionBehavior: .deliverImmediately
        )
        showOpenCount()
    }

    /// Where the item is on screen, so the panel can open right under it.
    private var frameOnScreen: NSRect? {
        guard let button = item.button, let window = button.window else { return nil }
        return window.convertToScreen(button.convert(button.bounds, to: nil))
    }

    @objc private func togglePanel() {
        panel.toggle(below: frameOnScreen)
    }

    /// `lest show` lands here. Whoever ran it may be typing somewhere else, so the panel
    /// opens without taking the keyboard.
    @objc private func showPanelWithoutFocus() {
        panel.show(below: frameOnScreen, takingFocus: false)
    }

    /// Shows the current count and arranges to be called again when it changes.
    private func showOpenCount() {
        let count = withObservationTracking {
            model.openCount
        } onChange: { [weak self] in
            Task { @MainActor in self?.showOpenCount() }
        }
        item.button?.title = count > 0 ? " \(count)" : ""
        item.button?.setAccessibilityLabel("Lest, \(openNotesLabel(count))")
    }
}
