import AppKit

/// Shows a project's folder in Finder.
///
/// The path comes from the notes file, which anything that runs `lest add` can write. Opening
/// it would launch an app when it leads to one, so the folder is shown in a Finder window
/// instead, and only when it is a plain folder.
enum ProjectFolder {
    /// The folder at `path`, or nil when there is no plain folder there: nothing at all, a
    /// file, or a package such as an app.
    static func revealable(at path: String) -> URL? {
        let url = URL(filePath: path, directoryHint: .isDirectory)
        let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .isPackageKey])
        guard values?.isDirectory == true, values?.isPackage == false else { return nil }
        return url
    }

    @MainActor
    static func reveal(_ path: String) {
        guard let folder = revealable(at: path) else { return }
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: folder.path(percentEncoded: false))
    }
}
