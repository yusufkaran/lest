import Foundation

/// The notes of one project, split into what is still open and what is done.
public struct ProjectGroup: Identifiable, Equatable, Sendable {
    public var name: String
    public var path: String?
    public var open: [Note] = []
    public var done: [Note] = []

    public var id: String { name }

    /// Groups notes by project. Projects with the most recently added open note come first,
    /// so whatever is being worked on now stays at the top; notes are newest first.
    public static func grouping(_ notes: [Note]) -> [ProjectGroup] {
        // Dates are saved to the second, so position in the file breaks ties between notes
        // added in quick succession.
        let newestFirst = notes.enumerated().sorted { first, second in
            first.element.createdAt == second.element.createdAt
                ? first.offset > second.offset
                : first.element.createdAt > second.element.createdAt
        }

        var groups: [String: ProjectGroup] = [:]
        var namesWithOpenNotes: [String] = []
        for (_, note) in newestFirst {
            var group = groups[note.project] ?? ProjectGroup(name: note.project)
            group.path = group.path ?? note.path
            if note.isDone {
                group.done.append(note)
            } else {
                if group.open.isEmpty { namesWithOpenNotes.append(note.project) }
                group.open.append(note)
            }
            groups[note.project] = group
        }

        let finishedNames = groups.keys.filter { !namesWithOpenNotes.contains($0) }.sorted()
        return (namesWithOpenNotes + finishedNames).compactMap { groups[$0] }
    }
}
