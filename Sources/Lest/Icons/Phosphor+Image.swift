import AppKit

extension Phosphor {
    @MainActor private static var images: [String: NSImage] = [:]

    /// The icon as a template image of the given size, so it takes on the foreground color
    /// the way an SF Symbol does. The image stays a vector, so it is sharp at any size.
    @MainActor
    func image(pointSize: Double) -> NSImage {
        let key = "\(rawValue)@\(pointSize)"
        if let image = Self.images[key] { return image }

        let image = NSImage(data: Data(svg.utf8)) ?? NSImage()
        image.size = NSSize(width: pointSize, height: pointSize)
        image.isTemplate = true
        Self.images[key] = image
        return image
    }
}
