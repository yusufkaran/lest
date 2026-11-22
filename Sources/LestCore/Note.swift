import Foundation

/// One thing to remember, tied to the project it was written for.
public struct Note: Codable, Identifiable, Equatable, Sendable {
    /// Project used when a note is not written from inside any project folder.
    public static let defaultProject = "General"

    public var id: String
    public var text: String
    public var project: String
    /// Root folder of the project, known when the note was added from inside it.
    public var path: String?
    public var createdAt: Date
    public var doneAt: Date?

    public var isDone: Bool { doneAt != nil }

    /// Prefix shown in the command line; long enough to stay unique in a personal list.
    public var shortID: String { String(id.prefix(8)) }

    public init(
        id: String = UUID().uuidString.lowercased(),
        text: String,
        project: String,
        path: String? = nil,
        createdAt: Date = .now,
        doneAt: Date? = nil
    ) {
        self.id = id
        self.text = text
        self.project = project
        self.path = path
        self.createdAt = createdAt
        self.doneAt = doneAt
    }
}
