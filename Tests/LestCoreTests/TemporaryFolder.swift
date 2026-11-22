import Foundation

/// A scratch folder that is removed when the test finishes.
final class TemporaryFolder: Sendable {
    let url: URL

    init() throws {
        // Resolved because /var is a symlink on macOS and project paths are compared as text.
        url = URL.temporaryDirectory
            .resolvingSymlinksInPath()
            .appending(path: "lest-tests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }

    func makeFolder(_ path: String) throws -> URL {
        let folder = url.appending(path: path, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }
}
