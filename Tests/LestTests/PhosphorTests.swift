import AppKit
import Testing
@testable import Lest

@MainActor
struct PhosphorTests {
    /// An SVG the system cannot read would otherwise only show up as a blank spot in the panel.
    @Test(arguments: Phosphor.allCases)
    func everyIconDecodes(icon: Phosphor) {
        let image = icon.image(pointSize: 16)

        #expect(!image.representations.isEmpty)
        #expect(image.isTemplate)
        #expect(image.size == NSSize(width: 16, height: 16))
    }
}
