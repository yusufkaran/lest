import Foundation

/// Connects coding tools to Lest and reports which ones are connected.
///
/// Nothing is recorded about a connection: a tool is connected when its files are in place, so
/// the answer stays right when someone deletes them by hand.
public struct ToolConnections: Sendable {
    public enum Status: Equatable, Sendable {
        /// The tool is not on this Mac.
        case notInstalled
        case notConnected
        /// Connected by an earlier version of Lest: some files are missing or differ.
        case outdated
        case connected
    }

    public let home: URL

    public init(home: URL) {
        self.home = home
    }

    public static var standard: ToolConnections {
        ToolConnections(home: FileManager.default.homeDirectoryForCurrentUser)
    }

    public func files(of tool: CodingTool) -> [ManagedFile] {
        tool.files(in: home)
    }

    public func status(of tool: CodingTool) -> Status {
        let files = files(of: tool)
        let current = files.filter { contents(of: $0.url) == $0.contents }
        if current.count == files.count {
            return .connected
        }
        if files.contains(where: { contents(of: $0.url) != nil }) {
            return .outdated
        }
        return isDirectory(tool.settingsFolder(in: home)) ? .notConnected : .notInstalled
    }

    /// Writes the tool's files, replacing ones left by an earlier version.
    @discardableResult
    public func connect(_ tool: CodingTool) throws -> [ManagedFile] {
        let files = files(of: tool)
        for file in files {
            try FileManager.default.createDirectory(
                at: file.url.deletingLastPathComponent(),
                withIntermediateDirectories: true
            )
            try Data(file.contents.utf8).write(to: file.url, options: .atomic)
        }
        return files
    }

    /// Deletes the tool's files and returns the ones that were there.
    @discardableResult
    public func disconnect(_ tool: CodingTool) throws -> [URL] {
        let present = files(of: tool).map(\.url).filter { contents(of: $0) != nil }
        for url in present {
            try FileManager.default.removeItem(at: url)
        }

        // The skill folder is Lest's own, but it only goes when nothing else was put in it.
        let skillFolder = tool.skillFolder(in: home)
        let leftovers = try? FileManager.default.contentsOfDirectory(atPath: skillFolder.path(percentEncoded: false))
        if leftovers?.isEmpty == true {
            try FileManager.default.removeItem(at: skillFolder)
        }
        return present
    }

    /// Brings the files of connected tools up to date after Lest itself was updated.
    public func refresh() throws {
        for tool in CodingTool.allCases where status(of: tool) == .outdated {
            try connect(tool)
        }
    }

    private func contents(of url: URL) -> String? {
        try? String(contentsOf: url, encoding: .utf8)
    }

    private func isDirectory(_ url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path(percentEncoded: false), isDirectory: &isDirectory)
            && isDirectory.boolValue
    }
}
