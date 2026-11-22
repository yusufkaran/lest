import Foundation

public enum NoteStoreError: Error, Equatable, LocalizedError {
    /// The notes file exists but cannot be decoded. It is left untouched so nothing is lost.
    case unreadable(path: String)
    case lockFailed(path: String)

    public var errorDescription: String? {
        switch self {
        case .unreadable(let path):
            "The notes file cannot be read and needs fixing by hand: \(path)"
        case .lockFailed(let path):
            "Could not lock the notes file: \(path)"
        }
    }
}
