import Foundation

/// The notes completed on one day, for looking back at what got done.
public struct CompletedDay: Identifiable, Equatable, Sendable {
    /// Start of the day the notes were completed on.
    public var day: Date
    /// Most recently completed first.
    public var notes: [Note]

    public var id: Date { day }

    /// Groups the completed notes by the day they were completed on, most recent day first.
    /// Open notes are left out.
    public static func grouping(_ notes: [Note], calendar: Calendar = .current) -> [CompletedDay] {
        // Dates are saved to the second, so position in the file breaks ties between notes
        // completed in quick succession.
        typealias Entry = (offset: Int, doneAt: Date, note: Note)
        let entries: [Entry] = notes.enumerated().compactMap { offset, note in
            guard let doneAt = note.doneAt else { return nil }
            return (offset, doneAt, note)
        }
        let completed = entries.sorted { (first: Entry, second: Entry) -> Bool in
            first.doneAt == second.doneAt ? first.offset > second.offset : first.doneAt > second.doneAt
        }

        var days: [CompletedDay] = []
        for entry in completed {
            let day = calendar.startOfDay(for: entry.doneAt)
            if days.last?.day == day {
                days[days.count - 1].notes.append(entry.note)
            } else {
                days.append(CompletedDay(day: day, notes: [entry.note]))
            }
        }
        return days
    }
}
