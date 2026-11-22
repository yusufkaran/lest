import AppKit
import LestCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let loginItem = LoginItem()
        loginItem.enableOnFirstLaunch()
        // An update may bring a newer skill; tools that are already connected get it here.
        try? ToolConnections.standard.refresh()

        let model = AppModel()
        let panel = PanelController(model: model, loginItem: loginItem)
        statusItem = StatusItemController(model: model, panel: panel)
    }
}
