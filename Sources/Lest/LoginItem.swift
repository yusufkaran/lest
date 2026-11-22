import Observation
import ServiceManagement

/// Whether the app starts when the user logs in.
@MainActor @Observable
final class LoginItem {
    var isEnabled = SMAppService.mainApp.status == .enabled
    private(set) var errorMessage: String?

    /// Turns launch at login on the first time the app runs, because a reminder list that is
    /// gone after a restart does not remind anyone. The user can switch it off afterwards.
    func enableOnFirstLaunch() {
        let key = "didSetUpLoginItem"
        // Only a bundled app can be a login item; this skips `swift run` during development.
        guard Bundle.main.bundleIdentifier != nil, !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)
        isEnabled = true
        apply()
    }

    /// Registers or unregisters the app so the system matches `isEnabled`.
    func apply() {
        let service = SMAppService.mainApp
        guard isEnabled != (service.status == .enabled) else { return }

        do {
            if isEnabled {
                try service.register()
            } else {
                try service.unregister()
            }
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't change the Open at Login setting: \(error.localizedDescription)"
            isEnabled = service.status == .enabled
        }
    }
}
