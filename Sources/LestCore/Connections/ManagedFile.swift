import Foundation

/// A file Lest writes into a coding tool's folder and keeps up to date.
public struct ManagedFile: Equatable, Sendable {
    public var url: URL
    public var contents: String
}
