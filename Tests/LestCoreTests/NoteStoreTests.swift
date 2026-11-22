import Foundation
import Testing
@testable import LestCore

struct NoteStoreTests {
    let folder: TemporaryFolder
    let store: NoteStore

    init() throws {
        folder = try TemporaryFolder()
        store = NoteStore(directory: folder.url.appending(path: "store", directoryHint: .isDirectory))
    }

    @Test func loadsNothingBeforeAnythingIsSaved() throws {
        #expect(try store.load().isEmpty)
    }

    @Test func savedNotesComeBackUnchanged() throws {
        let note = Note(
            text: "Rate limit için retry ekle",
            project: "Atlas",
            path: "/tmp/Atlas",
            createdAt: Date(timeIntervalSince1970: 1_800_000_000),
            doneAt: Date(timeIntervalSince1970: 1_800_000_500)
        )
        try store.update { $0.append(note) }

        #expect(try store.load() == [note])
    }

    @Test func unreadableFileIsReportedAndLeftAlone() throws {
        try store.createDirectoryIfNeeded()
        let garbage = Data("not json".utf8)
        try garbage.write(to: store.fileURL)

        #expect(throws: NoteStoreError.self) {
            try store.update { $0.append(Note(text: "x", project: "y")) }
        }
        #expect(try Data(contentsOf: store.fileURL) == garbage)
    }

    @Test func simultaneousWritersDoNotLoseNotes() async throws {
        let store = store
        try await withThrowingTaskGroup(of: Void.self) { group in
            for index in 0..<40 {
                group.addTask {
                    try store.update { $0.append(Note(text: "not \(index)", project: "Yük")) }
                }
            }
            try await group.waitForAll()
        }

        #expect(try store.load().count == 40)
    }
}
