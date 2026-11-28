import Foundation
import Testing
@testable import LestCore

struct CompletedDayTests {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private let day: TimeInterval = 24 * 3600

    private func note(_ text: String, doneAt seconds: TimeInterval?) -> Note {
        Note(
            text: text,
            project: "Alfa",
            createdAt: Date(timeIntervalSince1970: 0),
            doneAt: seconds.map { Date(timeIntervalSince1970: $0) }
        )
    }

    @Test func openNotesAreLeftOut() {
        let days = CompletedDay.grouping([note("açık", doneAt: nil)], calendar: calendar)

        #expect(days.isEmpty)
    }

    @Test func notesAreGroupedByDayMostRecentFirst() {
        let days = CompletedDay.grouping([
            note("pazartesi sabah", doneAt: 9 * 3600),
            note("salı", doneAt: day + 3600),
            note("pazartesi akşam", doneAt: 20 * 3600),
        ], calendar: calendar)

        #expect(days.map(\.day) == [Date(timeIntervalSince1970: day), Date(timeIntervalSince1970: 0)])
        #expect(days.map { $0.notes.map(\.text) } == [["salı"], ["pazartesi akşam", "pazartesi sabah"]])
    }

    @Test func notesCompletedInTheSameSecondKeepLatestInFileFirst() {
        let days = CompletedDay.grouping([
            note("önce", doneAt: 100),
            note("sonra", doneAt: 100),
        ], calendar: calendar)

        #expect(days.first?.notes.map(\.text) == ["sonra", "önce"])
    }
}
