import Observation

/// Lets the panel's views react to the panel being opened: the views stay alive while the
/// panel is hidden, so they do not "appear" again each time.
@MainActor @Observable
final class PanelPresentation {
    /// Goes up every time the panel opens ready for typing.
    private(set) var count = 0

    /// Whether the panel shows the completed notes instead of the open ones. Completed notes
    /// are looked at now and then, so they get a page of their own and the panel always opens
    /// on the open notes.
    var showsCompleted = false

    func didShow() {
        count += 1
    }
}
