import Foundation

enum DirectoryWatcher {
    /// Emits whenever a file in `directory` is created, replaced, or removed.
    ///
    /// The notes file is always replaced by renaming a new file over it, which shows up as a
    /// change to the directory rather than to the file itself.
    static func changes(in directory: URL) -> AsyncStream<Void> {
        AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
            let descriptor = open(directory.path(percentEncoded: false), O_EVTONLY)
            guard descriptor >= 0 else {
                continuation.finish()
                return
            }

            let source = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: descriptor,
                eventMask: .write,
                queue: .global(qos: .utility)
            )
            source.setEventHandler { continuation.yield() }
            source.setCancelHandler { close(descriptor) }
            continuation.onTermination = { _ in source.cancel() }
            source.resume()
        }
    }
}
