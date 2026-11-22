import Observation

/// Lets the panel's views react to the panel being opened: the views stay alive while the
/// panel is hidden, so they do not "appear" again each time.
@MainActor @Observable
final class PanelPresentation {
    /// Goes up every time the panel opens ready for typing.
    private(set) var count = 0

    func didShow() {
        count += 1
    }
}
