import Foundation
import Testing
@testable import LestCore

struct ProjectGroupTests {
    private func note(_ text: String, _ project: String, at seconds: TimeInterval, done: Bool = false) -> Note {
        let created = Date(timeIntervalSince1970: seconds)
        return Note(text: text, project: project, createdAt: created, doneAt: done ? created : nil)
    }

    @Test func projectWithNewestOpenNoteComesFirst() {
        let groups = ProjectGroup.grouping([
            note("eski", "Alfa", at: 100),
            note("yeni", "Beta", at: 300),
            note("bitmiş ama en yeni", "Alfa", at: 900, done: true),
        ])

        #expect(groups.map(\.name) == ["Beta", "Alfa"])
    }

    @Test func notesAreNewestFirstAndSplitByState() {
        let groups = ProjectGroup.grouping([
            note("bir", "Alfa", at: 100),
            note("iki", "Alfa", at: 200, done: true),
            note("üç", "Alfa", at: 300),
        ])

        #expect(groups.first?.open.map(\.text) == ["üç", "bir"])
        #expect(groups.first?.done.map(\.text) == ["iki"])
    }

    @Test func notesFromTheSameSecondKeepLatestAddedFirst() {
        let groups = ProjectGroup.grouping([
            note("önce eklenen", "Alfa", at: 100),
            note("sonra eklenen", "Alfa", at: 100),
        ])

        #expect(groups.first?.open.map(\.text) == ["sonra eklenen", "önce eklenen"])
    }

    @Test func projectFolderComesFromTheLatestNoteThatKnowsIt() {
        var known = note("klasörlü", "Alfa", at: 100)
        known.path = "/tmp/Alfa"

        let groups = ProjectGroup.grouping([known, note("klasörsüz", "Alfa", at: 200)])

        #expect(groups.first?.path == "/tmp/Alfa")
    }
}
