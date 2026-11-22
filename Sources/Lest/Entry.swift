import AppKit
import LestCore

@main
enum Entry {
    /// The same binary is the menu bar app and the `lest` command: with a command as its
    /// first argument it runs that and exits, otherwise it starts the app.
    @MainActor
    static func main() {
        let arguments = Array(CommandLine.arguments.dropFirst())
        guard let command = arguments.first, CommandLineTool.recognizes(command) else {
            runApp()
            return
        }

        let tool = CommandLineTool(
            store: .standard,
            workingDirectory: .currentDirectory(),
            connections: .standard,
            showPanel: showPanelOfRunningApp
        )
        let output = tool.run(arguments)
        if output.exitCode == 0 {
            print(output.text)
        } else {
            FileHandle.standardError.write(Data("\(output.text)\n".utf8))
        }
        exit(output.exitCode)
    }

    @MainActor
    private static func runApp() {
        let delegate = AppDelegate()
        let application = NSApplication.shared
        application.delegate = delegate
        application.setActivationPolicy(.accessory)
        // The application only keeps a weak reference to its delegate.
        withExtendedLifetime(delegate) {
            application.run()
        }
    }

    private static func showPanelOfRunningApp() -> Bool {
        let isRunning = NSRunningApplication
            .runningApplications(withBundleIdentifier: AppSignal.bundleIdentifier)
            .contains { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }
        guard isRunning else { return false }

        DistributedNotificationCenter.default().postNotificationName(
            AppSignal.showPanel,
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
        return true
    }
}
