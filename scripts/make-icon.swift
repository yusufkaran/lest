// Draws the app icon and writes it as a 1024 px PNG.
// Usage: swift scripts/make-icon.swift <output.png>   (see `make app-icon`)
import AppKit

let side = 1024.0
let glyphSide = 520.0
guard CommandLine.arguments.count == 2 else {
    FileHandle.standardError.write(Data("usage: make-icon.swift <output.png>\n".utf8))
    exit(2)
}

guard
    let bitmap = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: Int(side), pixelsHigh: Int(side), bitsPerSample: 8,
        samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    ),
    let context = NSGraphicsContext(bitmapImageRep: bitmap),
    let gradient = NSGradient(
        starting: NSColor(red: 1.0, green: 0.76, blue: 0.24, alpha: 1),
        ending: NSColor(red: 1.0, green: 0.52, blue: 0.10, alpha: 1)
    ),
    // The same Phosphor icon the menu bar item shows.
    let glyph = NSImage(contentsOf: URL(filePath: "Resources/Phosphor/list-checks-bold.svg"))
else {
    fatalError("Could not set up drawing for the icon.")
}

/// The glyph is black in its file; painting over only what it already covers makes it white.
let whiteGlyph = NSImage(size: NSSize(width: glyphSide, height: glyphSide), flipped: false) { rect in
    glyph.draw(in: rect)
    NSColor.white.set()
    rect.fill(using: .sourceAtop)
    return true
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context

// The standard macOS icon shape: an 824 pt rounded square centered on the 1024 pt canvas.
let plate = NSRect(x: 100, y: 100, width: 824, height: 824)
gradient.draw(in: NSBezierPath(roundedRect: plate, xRadius: 186, yRadius: 186), angle: -90)

let glyphOrigin = (side - glyphSide) / 2
whiteGlyph.draw(in: NSRect(x: glyphOrigin, y: glyphOrigin, width: glyphSide, height: glyphSide))

NSGraphicsContext.restoreGraphicsState()

guard let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("Could not encode the icon as PNG.")
}
try png.write(to: URL(filePath: CommandLine.arguments[1]))
