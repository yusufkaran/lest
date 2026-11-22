import Foundation

enum CommandError: Error, Equatable {
    /// The command was typed wrong; the usage text is shown with it.
    case usage(String)
    /// The command was understood but could not be carried out.
    case failure(String)
}
