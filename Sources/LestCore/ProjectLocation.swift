import Foundation

/// The project a folder belongs to.
public struct ProjectLocation: Equatable, Sendable {
    public var name: String
    public var path: String?

    public init(name: String, path: String?) {
        self.name = name
        self.path = path
    }

    /// Finds the project for `directory`: the enclosing git repository, otherwise the folder
    /// itself. A git worktree resolves to its main repository, so notes written from a
    /// worktree land under the real project name instead of the branch folder.
    public static func locate(from directory: URL, home: URL = .homeDirectory) -> ProjectLocation {
        let start = directory.standardizedFileURL
        let root = repositoryRoot(containing: start) ?? start
        let rootPath = root.path(percentEncoded: false).trimmingSuffix("/")
        let homePath = home.standardizedFileURL.path(percentEncoded: false).trimmingSuffix("/")

        if rootPath.isEmpty || rootPath == homePath {
            return ProjectLocation(name: Note.defaultProject, path: nil)
        }
        return ProjectLocation(name: root.lastPathComponent, path: rootPath)
    }

    private static func repositoryRoot(containing directory: URL) -> URL? {
        var candidate = directory
        // One step per path component: a folder has no more ancestors than that, and asking
        // for the parent of the root does not reliably return the root itself.
        for _ in directory.pathComponents {
            let gitURL = candidate.appending(path: ".git")
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: gitURL.path(percentEncoded: false), isDirectory: &isDirectory) {
                return isDirectory.boolValue ? candidate : mainRepository(forLinkedGitFile: gitURL) ?? candidate
            }
            candidate = candidate.deletingLastPathComponent()
        }
        return nil
    }

    /// In a worktree `.git` is a file such as `gitdir: /repo/.git/worktrees/branch`.
    private static func mainRepository(forLinkedGitFile gitURL: URL) -> URL? {
        guard
            let contents = try? String(contentsOf: gitURL, encoding: .utf8),
            let line = contents.split(whereSeparator: \.isNewline).first(where: { $0.hasPrefix("gitdir:") })
        else { return nil }

        let gitDirectory = line.dropFirst("gitdir:".count).trimmingCharacters(in: .whitespaces)
        let resolved = URL(filePath: gitDirectory, relativeTo: gitURL.deletingLastPathComponent())
            .standardizedFileURL
            .path(percentEncoded: false)
        guard let marker = resolved.range(of: "/.git/worktrees/") else { return nil }
        return URL(filePath: String(resolved[..<marker.lowerBound]), directoryHint: .isDirectory)
    }
}

private extension String {
    func trimmingSuffix(_ suffix: String) -> String {
        hasSuffix(suffix) ? String(dropLast(suffix.count)) : self
    }
}
