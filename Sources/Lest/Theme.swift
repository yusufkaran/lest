import SwiftUI
import LestCore

/// Sizes, corner radii and colors shared by the panel's views.
enum Theme {
    // MARK: Layout

    static let panelWidth: Double = 380
    static let listMaxHeight: Double = 430
    static let padding: Double = 14
    static let blockSpacing: Double = 12
    static let cardPadding: Double = 6
    static let cardSpacing: Double = 10
    static let rowPadding: Double = 8
    static let itemSpacing: Double = 10
    static let chipSpacing: Double = 6
    static let textSpacing: Double = 2
    static let projectFieldWidth: Double = 130
    static let chipMaxWidth: Double = 170

    /// Gap between the panel and the menu bar, and between the panel and the screen edges.
    static let panelMargin: Double = 8
    /// How long a click that has just closed the panel is kept from opening it again.
    static let reopenDelay: TimeInterval = 0.3

    // MARK: Corners

    static let panelRadius: Double = 24
    static let cardRadius: Double = 16
    static let rowRadius: Double = 11
    static let controlRadius: Double = 10
    static let tileRadius: Double = 6

    // MARK: Icons and controls

    static let menuBarIconSize: Double = 18
    static let iconSize: Double = 16
    static let smallIconSize: Double = 12
    static let checkboxSize: Double = 20
    static let tileSize: Double = 20
    static let dotSize: Double = 7
    static let controlSize: Double = 30
    static let brandTileSize: Double = 34
    static let sendButtonSize: Double = 24
    static let emptyTileSize: Double = 60

    /// Moves a checkbox up so its center sits on the middle of the first line of note text.
    static let checkboxBaselineOffset: Double = 5.5

    // MARK: Colors

    static let accent = Color(red: 1.0, green: 0.56, blue: 0.11)
    static let brandGradient = LinearGradient(
        colors: [Color(red: 1.0, green: 0.76, blue: 0.24), Color(red: 1.0, green: 0.52, blue: 0.10)],
        startPoint: .top,
        endPoint: .bottom
    )

    static let animation = Animation.snappy(duration: 0.22)

    /// Hues that are easy to tell apart and stay clear of the orange accent. Each is dark
    /// enough for the white letter on a project tile.
    private static let projectColors: [Color] = [
        Color(red: 0.23, green: 0.51, blue: 0.96),  // blue
        Color(red: 0.55, green: 0.36, blue: 0.96),  // violet
        Color(red: 0.93, green: 0.28, blue: 0.60),  // pink
        Color(red: 0.06, green: 0.72, blue: 0.51),  // emerald
        Color(red: 0.02, green: 0.71, blue: 0.83),  // cyan
        Color(red: 0.39, green: 0.40, blue: 0.95),  // indigo
        Color(red: 0.96, green: 0.25, blue: 0.37),  // rose
        Color(red: 0.08, green: 0.72, blue: 0.65),  // teal
        Color(red: 0.85, green: 0.27, blue: 0.94),  // fuchsia
        Color(red: 0.05, green: 0.65, blue: 0.91),  // sky
    ]

    /// A color that stays the same for a project across launches, which `hashValue` would not.
    static func color(forProject name: String) -> Color {
        // Notes that belong to no project should not look like one more project.
        guard name != Note.defaultProject else { return .gray }

        let hash = name.utf8.reduce(UInt64(14_695_981_039_346_656_037)) { hash, byte in
            (hash ^ UInt64(byte)) &* 1_099_511_628_211
        }
        return projectColors[Int(hash % UInt64(projectColors.count))]
    }
}
