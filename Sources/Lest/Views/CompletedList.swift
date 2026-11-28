import SwiftUI
import LestCore

/// Completed notes by the day they were completed on, most recent first.
struct CompletedList: View {
    let days: [CompletedDay]
    let model: AppModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if days.isEmpty {
            CompletedEmptyState()
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.cardSpacing) {
                    ForEach(days) { day in
                        VStack(alignment: .leading, spacing: Theme.chipSpacing) {
                            DayTitle(day: day.day)
                                .padding(.horizontal, Theme.rowPadding + Theme.cardPadding)
                            VStack(alignment: .leading, spacing: Theme.textSpacing) {
                                ForEach(day.notes) { note in
                                    CompletedRow(note: note, model: model)
                                }
                            }
                            .padding(Theme.cardPadding)
                            .background(.quinary, in: .rect(cornerRadius: Theme.cardRadius))
                        }
                    }
                }
                .padding(.horizontal, Theme.padding)
                .animation(reduceMotion ? nil : Theme.animation, value: days)
            }
            .scrollIndicators(.never)
            .frame(maxHeight: Theme.listMaxHeight)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

/// "Today", "Yesterday", or the date.
private struct DayTitle: View {
    let day: Date

    var body: some View {
        Group {
            if Calendar.current.isDateInToday(day) {
                Text("Today")
            } else if Calendar.current.isDateInYesterday(day) {
                Text("Yesterday")
            } else if Calendar.current.isDate(day, equalTo: .now, toGranularity: .year) {
                Text(day, format: .dateTime.weekday(.wide).month(.wide).day())
            } else {
                Text(day, format: .dateTime.month(.wide).day().year())
            }
        }
        .font(.subheadline)
        .bold()
        .foregroundStyle(.secondary)
        .accessibilityAddTraits(.isHeader)
    }
}

private struct CompletedEmptyState: View {
    var body: some View {
        VStack(spacing: Theme.itemSpacing) {
            PhosphorIcon(.checkCircleDuotone, size: Theme.emptyTileSize / 2)
                .foregroundStyle(Theme.accent)
                .frame(width: Theme.emptyTileSize, height: Theme.emptyTileSize)
                .background(Theme.accent.opacity(0.15), in: .rect(cornerRadius: Theme.cardRadius))
            Text("Nothing completed yet")
                .font(.headline)
            Text("Notes you check off are kept here.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Theme.padding * 3)
        .padding(.vertical, Theme.padding * 2)
        .accessibilityElement(children: .combine)
    }
}
