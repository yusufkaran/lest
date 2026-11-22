import Foundation

/// What the command line and the running menu bar app need to know about each other.
public enum AppSignal {
    public static let bundleIdentifier = "com.karanlabs.lest"

    /// Distributed notification that asks the running app to open its panel.
    public static let showPanel = Notification.Name("com.karanlabs.lest.showPanel")
}
