import Foundation

/// The `lest` command line. This is how Claude adds and manages notes; the menu bar app
/// picks the changes up from the shared notes file.
public struct CommandLineTool {
    public struct Output: Equatable, Sendable {
        public var text: String
        public var exitCode: Int32
    }

    public static let usage = """
        Lest — the to-do list in your menu bar

        Usage:
          lest add <note> [--project <name>]  Adds a note. Without --project, the project is
                                              the folder you are in.
          lest list [--here | --project <name>] [--all] [--json]
                                              Lists open notes. --here shows this project only,
                                              --all includes completed notes.
          lest done <id>...                   Marks notes as done.
          lest undone <id>...                 Reopens notes.
          lest rm <id>...                     Deletes notes.
          lest projects                       Lists projects with their open note counts.
          lest show                           Opens the panel in the menu bar.
          lest setup [claude | codex]... [--remove | --status]
                                              Connects coding tools: installs the skill and lets
                                              them run lest without asking. Without a tool,
                                              connects every one found on this Mac.
        """

    private static let commands: Set<String> = [
        "add", "list", "done", "undone", "rm", "projects", "show", "setup", "help", "--help", "-h",
    ]

    private let store: NoteStore
    private let workingDirectory: URL
    private let connections: ToolConnections
    private let showPanel: () -> Bool

    /// - Parameter showPanel: Asks the running app to open its panel and reports whether the
    ///   app is running. It is passed in because reaching the app needs AppKit, and so tests
    ///   do not pop the real panel open.
    public init(
        store: NoteStore,
        workingDirectory: URL,
        connections: ToolConnections,
        showPanel: @escaping () -> Bool = { false }
    ) {
        self.store = store
        self.workingDirectory = workingDirectory
        self.connections = connections
        self.showPanel = showPanel
    }

    /// Whether `argument` starts a command. The app binary doubles as the command line tool,
    /// so anything else means it was launched as an app.
    public static func recognizes(_ argument: String) -> Bool {
        commands.contains(argument)
    }

    public func run(_ arguments: [String]) -> Output {
        do {
            return Output(text: try execute(CommandInvocation(arguments)), exitCode: 0)
        } catch CommandError.usage(let message) {
            return Output(text: "\(message)\n\n\(Self.usage)", exitCode: 2)
        } catch CommandError.failure(let message) {
            return Output(text: message, exitCode: 1)
        } catch {
            return Output(text: error.localizedDescription, exitCode: 1)
        }
    }

    private func execute(_ invocation: CommandInvocation) throws -> String {
        switch invocation.command {
        case "add":
            try add(invocation)
        case "list":
            try list(invocation)
        case "done":
            try change(invocation, verb: "Done") { notes, index in
                notes[index].doneAt = notes[index].doneAt ?? .now
            }
        case "undone":
            try change(invocation, verb: "Reopened") { notes, index in
                notes[index].doneAt = nil
            }
        case "rm":
            try remove(invocation)
        case "projects":
            try projects()
        case "show":
            try show()
        case "setup":
            try setup(invocation)
        case "help", "--help", "-h":
            Self.usage
        default:
            throw CommandError.usage("Unknown command: \(invocation.command)")
        }
    }

    private func add(_ invocation: CommandInvocation) throws -> String {
        let text = invocation.values.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { throw CommandError.usage("The note is empty.") }

        let location = ProjectLocation.locate(from: workingDirectory)
        let requested = invocation.project?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let name = requested.isEmpty ? location.name : requested
        let isCurrentProject = name.caseInsensitiveCompare(location.name) == .orderedSame

        let note = try store.update { notes in
            // Reuse the spelling already in the list so "atlas" and "Atlas"
            // do not become two projects.
            let existing = notes.last { $0.project.caseInsensitiveCompare(name) == .orderedSame }
            let note = Note(
                text: text,
                project: existing?.project ?? name,
                path: isCurrentProject ? location.path : nil
            )
            notes.append(note)
            return note
        }
        return "Added \(describe(note))"
    }

    private func list(_ invocation: CommandInvocation) throws -> String {
        guard !(invocation.here && invocation.project != nil) else {
            throw CommandError.usage("--here and --project cannot be used together.")
        }

        let filter = invocation.here ? ProjectLocation.locate(from: workingDirectory).name : invocation.project
        var groups = ProjectGroup.grouping(try store.load())
        if let filter {
            groups = groups.filter { $0.name.caseInsensitiveCompare(filter) == .orderedSame }
        }
        if !invocation.all {
            groups = groups.compactMap { group in
                var group = group
                group.done = []
                return group.open.isEmpty ? nil : group
            }
        }

        if invocation.json {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
            let data = try encoder.encode(groups.flatMap { $0.open + $0.done })
            return String(decoding: data, as: UTF8.self)
        }

        guard !groups.isEmpty else {
            return filter.map { "No open notes for \($0)." } ?? "No open notes."
        }
        return groups.map { group in
            let open = group.open.map { "  \($0.shortID)  \($0.text)" }
            let done = group.done.map { "  \($0.shortID)  ✓ \($0.text)" }
            return (["\(group.name) (\(group.open.count))"] + open + done).joined(separator: "\n")
        }
        .joined(separator: "\n")
    }

    private func change(
        _ invocation: CommandInvocation,
        verb: String,
        _ apply: (inout [Note], Int) -> Void
    ) throws -> String {
        guard !invocation.values.isEmpty else { throw CommandError.usage("Missing note id.") }

        let changed = try store.update { notes in
            try invocation.values.map { identifier in
                let index = try index(of: identifier, in: notes)
                apply(&notes, index)
                return notes[index]
            }
        }
        return changed.map { "\(verb) \(describe($0))" }.joined(separator: "\n")
    }

    private func remove(_ invocation: CommandInvocation) throws -> String {
        guard !invocation.values.isEmpty else { throw CommandError.usage("Missing note id.") }

        let removed = try store.update { notes in
            try invocation.values.map { identifier in
                notes.remove(at: try index(of: identifier, in: notes))
            }
        }
        return removed.map { "Deleted \(describe($0))" }.joined(separator: "\n")
    }

    private func projects() throws -> String {
        let groups = ProjectGroup.grouping(try store.load())
        guard !groups.isEmpty else { return "No projects yet." }
        return groups.map { "\($0.name) (\($0.open.count))" }.joined(separator: "\n")
    }

    private func show() throws -> String {
        guard showPanel() else {
            throw CommandError.failure("Lest is not running. Start it first: open -a Lest")
        }
        return "Panel opened."
    }

    private func setup(_ invocation: CommandInvocation) throws -> String {
        guard !(invocation.remove && invocation.status) else {
            throw CommandError.usage("--remove and --status cannot be used together.")
        }
        let supported = CodingTool.allCases.map { "\($0.name) (\($0.rawValue))" }.joined(separator: ", ")
        let named = try invocation.values.map { value in
            guard let tool = CodingTool(rawValue: value.lowercased()) else {
                throw CommandError.usage("Unknown tool: \(value). Supported: \(supported)")
            }
            return tool
        }

        if invocation.status {
            return (named.isEmpty ? CodingTool.allCases : named)
                .map { "\($0.name): \(describe(connections.status(of: $0)))" }
                .joined(separator: "\n")
        }
        if invocation.remove {
            return try (named.isEmpty ? CodingTool.allCases : named).map { tool in
                let removed = try connections.disconnect(tool)
                return removed.isEmpty
                    ? "\(tool.name) is not connected."
                    : report("\(tool.name) disconnected:", files: removed)
            }
            .joined(separator: "\n")
        }

        if let missing = named.first(where: { connections.status(of: $0) == .notInstalled }) {
            throw CommandError.failure("\(missing.name) was not found on this Mac.")
        }
        let tools = named.isEmpty
            ? CodingTool.allCases.filter { connections.status(of: $0) != .notInstalled }
            : named
        guard !tools.isEmpty else {
            throw CommandError.failure("No coding tool found to connect. Supported: \(supported)")
        }
        var lines = try tools.map { tool in
            report("\(tool.name) connected:", files: try connections.connect(tool).map(\.url))
        }
        if tools.contains(.codex) {
            lines.append("Codex sessions that are already open pick this up after a restart.")
        }
        return lines.joined(separator: "\n")
    }

    private func describe(_ status: ToolConnections.Status) -> String {
        switch status {
        case .notInstalled: "not installed"
        case .notConnected: "not connected"
        case .outdated: "out of date (`lest setup` updates it)"
        case .connected: "connected"
        }
    }

    /// A heading followed by the files it is about, with the home folder shortened to `~`.
    private func report(_ heading: String, files: [URL]) -> String {
        let home = connections.home.path(percentEncoded: false)
        let paths = files.map { file in
            let path = file.path(percentEncoded: false)
            return path.hasPrefix(home) ? "  ~/" + path.dropFirst(home.count).drop { $0 == "/" } : "  " + path
        }
        return ([heading] + paths).joined(separator: "\n")
    }

    /// Notes are addressed by any unambiguous prefix of their identifier.
    private func index(of identifier: String, in notes: [Note]) throws -> Int {
        let prefix = identifier.lowercased()
        let matches = notes.indices.filter { notes[$0].id.hasPrefix(prefix) }
        switch matches.count {
        case 1:
            return matches[0]
        case 0:
            throw CommandError.failure("No note with this id: \(identifier)")
        default:
            throw CommandError.failure("\(identifier) matches more than one note; use more characters.")
        }
    }

    private func describe(_ note: Note) -> String {
        "[\(note.shortID)] \(note.project): \(note.text)"
    }
}
