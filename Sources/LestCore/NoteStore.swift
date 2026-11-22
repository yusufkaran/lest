import Foundation

/// Reads and writes the shared notes file.
///
/// The menu bar app and every `lest` command go through this type and may run at the same
/// time, so each change holds an exclusive file lock and replaces the file atomically.
public struct NoteStore: Sendable {
    public let directory: URL

    public var fileURL: URL { directory.appending(path: "notes.json") }
    private var lockURL: URL { directory.appending(path: "notes.lock") }

    public init(directory: URL) {
        self.directory = directory
    }

    /// The store used outside tests. `LEST_DIR` moves it, which keeps experiments away from
    /// the real notes.
    public static var standard: NoteStore {
        if let override = ProcessInfo.processInfo.environment["LEST_DIR"], !override.isEmpty {
            return NoteStore(directory: URL(filePath: override, directoryHint: .isDirectory))
        }
        return NoteStore(
            directory: .applicationSupportDirectory.appending(path: "Lest", directoryHint: .isDirectory)
        )
    }

    public func createDirectoryIfNeeded() throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    public func load() throws -> [Note] {
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch CocoaError.fileReadNoSuchFile {
            return []
        }

        do {
            return try Self.decoder.decode(Document.self, from: data).notes
        } catch {
            throw NoteStoreError.unreadable(path: fileURL.path(percentEncoded: false))
        }
    }

    /// Applies `change` to the latest notes on disk and saves the result.
    @discardableResult
    public func update<Result>(_ change: (inout [Note]) throws -> Result) throws -> Result {
        try createDirectoryIfNeeded()

        let lockPath = lockURL.path(percentEncoded: false)
        let descriptor = open(lockPath, O_CREAT | O_RDWR, 0o644)
        guard descriptor >= 0 else { throw NoteStoreError.lockFailed(path: lockPath) }
        defer { close(descriptor) }
        guard flock(descriptor, LOCK_EX) == 0 else { throw NoteStoreError.lockFailed(path: lockPath) }
        defer { flock(descriptor, LOCK_UN) }

        var notes = try load()
        let original = notes
        let result = try change(&notes)
        if notes != original {
            let data = try Self.encoder.encode(Document(notes: notes))
            try data.write(to: fileURL, options: .atomic)
        }
        return result
    }

    private struct Document: Codable {
        var version = 1
        var notes: [Note]
    }

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
