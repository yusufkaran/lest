import Foundation
import Observation
import LestCore

/// The notes shown in the menu bar panel, kept in step with the shared notes file.
@MainActor @Observable
final class AppModel {
    private(set) var groups: [ProjectGroup] = []
    private(set) var errorMessage: String?

    @ObservationIgnored private let store: NoteStore

    var openCount: Int { groups.reduce(0) { $0 + $1.open.count } }
    var doneCount: Int { groups.reduce(0) { $0 + $1.done.count } }
    var projectNames: [String] { groups.map(\.name) }

    init(store: NoteStore = .standard) {
        self.store = store
        reload()
        watchForChanges()
    }

    func add(_ text: String, to project: String) {
        let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let project = project.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = project.isEmpty ? Note.defaultProject : project
        let path = groups.first { $0.name == name }?.path
        change { $0.append(Note(text: text, project: name, path: path)) }
    }

    func toggle(_ note: Note) {
        change { notes in
            guard let index = notes.firstIndex(where: { $0.id == note.id }) else { return }
            notes[index].doneAt = notes[index].isDone ? nil : .now
        }
    }

    func delete(_ note: Note) {
        change { $0.removeAll { $0.id == note.id } }
    }

    func clearDone() {
        change { $0.removeAll(where: \.isDone) }
    }

    private func change(_ body: (inout [Note]) -> Void) {
        do {
            let notes = try store.update { notes in
                body(&notes)
                return notes
            }
            show(notes)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func reload() {
        do {
            show(try store.load())
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func show(_ notes: [Note]) {
        let groups = ProjectGroup.grouping(notes)
        if groups != self.groups { self.groups = groups }
        errorMessage = nil
    }

    /// Claude adds notes by running `lest`, which rewrites the notes file behind the app's back.
    private func watchForChanges() {
        do {
            try store.createDirectoryIfNeeded()
        } catch {
            errorMessage = error.localizedDescription
            return
        }

        let changes = DirectoryWatcher.changes(in: store.directory)
        Task { [weak self] in
            for await _ in changes {
                self?.reload()
            }
        }
    }
}
