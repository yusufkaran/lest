import Foundation
import Testing
@testable import Lest
import LestCore

@MainActor
final class AppModelTests {
    private let directory = URL.temporaryDirectory.appending(path: "lest-model-\(UUID().uuidString)")
    private let store: NoteStore
    private let model: AppModel

    init() {
        store = NoteStore(directory: directory)
        model = AppModel(store: store)
    }

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    @Test func addedNoteIsShownAndSaved() throws {
        model.add("  README yaz  ", to: "Alfa")

        #expect(model.groups.map(\.name) == ["Alfa"])
        #expect(model.openCount == 1)
        #expect(try store.load().map(\.text) == ["README yaz"])
    }

    @Test func noteWithoutProjectGoesToTheGeneralProject() {
        model.add("Fatura gönder", to: "  ")

        #expect(model.projectNames == [Note.defaultProject])
    }

    @Test func blankNoteIsIgnored() throws {
        model.add("   ", to: "Alfa")

        #expect(try store.load().isEmpty)
    }

    @Test func newNoteInheritsTheFolderOfItsProject() throws {
        try store.update { $0.append(Note(text: "ilk", project: "Alfa", path: "/tmp/Alfa")) }
        let model = AppModel(store: store)

        model.add("ikinci", to: "Alfa")

        #expect(try store.load().last?.path == "/tmp/Alfa")
    }

    @Test func toggleCompletesAndReopens() throws {
        model.add("README yaz", to: "Alfa")
        let note = try #require(model.groups.first?.open.first)

        model.toggle(note)
        #expect(model.openCount == 0)
        #expect(model.doneCount == 1)

        model.toggle(note)
        #expect(model.openCount == 1)
        #expect(model.doneCount == 0)
    }

    @Test func deleteRemovesOnlyThatNote() throws {
        model.add("bir", to: "Alfa")
        model.add("iki", to: "Alfa")
        let newest = try #require(model.groups.first?.open.first)

        model.delete(newest)

        #expect(try store.load().map(\.text) == ["bir"])
    }

    @Test func clearDoneKeepsOpenNotes() throws {
        model.add("bir", to: "Alfa")
        model.add("iki", to: "Alfa")
        model.toggle(try #require(model.groups.first?.open.first))

        model.clearDone()

        #expect(try store.load().map(\.text) == ["bir"])
        #expect(model.doneCount == 0)
    }

    /// This is the path a note takes when Claude adds it with the `lest` command.
    @Test func noteWrittenByAnotherProcessShowsUp() async throws {
        try store.update { $0.append(Note(text: "dışarıdan eklendi", project: "Alfa")) }

        let deadline = ContinuousClock.now + .seconds(5)
        while model.openCount == 0, ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(20))
        }

        #expect(model.groups.first?.open.map(\.text) == ["dışarıdan eklendi"])
    }

    @Test func unreadableFileIsReportedInsteadOfShowingAnEmptyList() throws {
        try store.createDirectoryIfNeeded()
        try Data("bozuk".utf8).write(to: store.fileURL)

        let model = AppModel(store: store)

        #expect(model.errorMessage != nil)
    }
}
