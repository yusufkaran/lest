import Foundation
import Testing
@testable import Lest

struct ProjectFolderTests {
    private let directory = URL.temporaryDirectory
        .appending(path: "lest-folder-\(UUID().uuidString)", directoryHint: .isDirectory)

    @Test func aPlainFolderCanBeShown() throws {
        let folder = try makeFolder("Atlas")
        defer { cleanUp() }

        #expect(ProjectFolder.revealable(at: folder.path(percentEncoded: false)) != nil)
    }

    /// Opening an app would launch it, and the path is read from a file other programs write.
    @Test func anAppIsNotShown() throws {
        let app = try makeFolder("Tool.app")
        defer { cleanUp() }

        #expect(ProjectFolder.revealable(at: app.path(percentEncoded: false)) == nil)
    }

    @Test func aFileIsNotShown() throws {
        let file = try makeFolder("Atlas").appending(path: "run.command")
        defer { cleanUp() }
        try Data("#!/bin/sh\n".utf8).write(to: file)

        #expect(ProjectFolder.revealable(at: file.path(percentEncoded: false)) == nil)
    }

    @Test func aFolderThatIsGoneIsNotShown() {
        #expect(ProjectFolder.revealable(at: directory.appending(path: "nowhere").path(percentEncoded: false)) == nil)
    }

    private func makeFolder(_ name: String) throws -> URL {
        let folder = directory.appending(path: name, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder
    }

    private func cleanUp() {
        try? FileManager.default.removeItem(at: directory)
    }
}
