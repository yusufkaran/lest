import AppKit
import SwiftUI
import Testing
@testable import Lest
import LestCore

/// Where the images go. The suite is skipped unless this is set, so `swift test` stays quick.
private let snapshotDirectory = ProcessInfo.processInfo.environment["LEST_SNAPSHOT_DIR"]

/// Draws the menu bar panel off screen with sample notes and saves it as PNG files.
///
/// The panel only opens from a click on the menu bar, which a script cannot do without
/// accessibility permission, so this is the way to look at a layout change:
/// `make snapshot`, then open the images in `build/snapshots`.
///
/// Serialized because the "show done notes" setting is read from shared user defaults.
@MainActor
@Suite(.serialized, .enabled(if: snapshotDirectory != nil))
struct PanelSnapshotTests {
    @Test func lightPanel() throws {
        try snapshot(named: "panel-light", appearance: .aqua, notes: Self.sampleNotes)
    }

    @Test func darkPanel() throws {
        try snapshot(named: "panel-dark", appearance: .darkAqua, notes: Self.sampleNotes)
    }

    @Test func panelShowingDoneNotes() throws {
        UserDefaults.standard.set(true, forKey: "showsDone")
        defer { UserDefaults.standard.removeObject(forKey: "showsDone") }
        try snapshot(named: "panel-done", appearance: .aqua, notes: Self.sampleNotes)
    }

    @Test func emptyPanel() throws {
        try snapshot(named: "panel-empty", appearance: .aqua, notes: [])
    }

    private func snapshot(named name: String, appearance: NSAppearance.Name, notes: [Note]) throws {
        let directory = try #require(snapshotDirectory)
        let storeDirectory = URL.temporaryDirectory.appending(path: "lest-snapshot-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: storeDirectory) }
        let store = NoteStore(directory: storeDirectory)
        try store.update { $0 = notes }

        // The real panel blurs whatever is behind its window, which an off-screen drawing cannot
        // show, so a plain window color stands in for the frosted backdrop.
        let shape = RoundedRectangle(cornerRadius: Theme.panelRadius, style: .circular)
        let panel = NotesPanel(model: AppModel(store: store), loginItem: LoginItem(), presentation: PanelPresentation())
            .background(Color(nsColor: .windowBackgroundColor), in: shape)
            .overlay { shape.strokeBorder(.separator) }
        let hostingView = NSHostingView(rootView: panel)
        let window = NSWindow(
            contentRect: NSRect(origin: .zero, size: hostingView.fittingSize),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        window.appearance = NSAppearance(named: appearance)
        window.contentView = hostingView
        hostingView.layoutSubtreeIfNeeded()

        let bitmap = try #require(hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds))
        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmap)
        let png = try #require(bitmap.representation(using: .png, properties: [:]))
        let output = URL(filePath: directory, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        try png.write(to: output.appending(path: "\(name).png"))
    }

    private static var sampleNotes: [Note] {
        let hour: TimeInterval = 3600
        return [
            Note(
                text: "Send the invoices to the accountant",
                project: Note.defaultProject,
                createdAt: .now.addingTimeInterval(-9 * 24 * hour)
            ),
            Note(
                text: "Replace the old email address in the footer",
                project: "landing-page",
                path: "/tmp/landing-page",
                createdAt: .now.addingTimeInterval(-3 * 24 * hour)
            ),
            Note(
                text: "Measure the Lighthouse score",
                project: "landing-page",
                createdAt: .now.addingTimeInterval(-4 * 24 * hour),
                doneAt: .now
            ),
            Note(
                text: "Verify the Stripe webhook signature; unsigned requests are accepted for now",
                project: "Atlas",
                path: "/tmp/Atlas",
                createdAt: .now.addingTimeInterval(-26 * hour)
            ),
            Note(
                text: "Add a retry for rate limits in the import worker",
                project: "Atlas",
                path: "/tmp/Atlas",
                createdAt: .now.addingTimeInterval(-20 * 60)
            ),
        ]
    }
}
