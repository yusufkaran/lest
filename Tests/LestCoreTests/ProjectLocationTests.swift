import Foundation
import Testing
@testable import LestCore

struct ProjectLocationTests {
    let folder: TemporaryFolder

    init() throws {
        folder = try TemporaryFolder()
    }

    @Test func subfolderOfRepositoryBelongsToRepository() throws {
        let repository = try folder.makeFolder("Atlas")
        _ = try folder.makeFolder("Atlas/.git")
        let nested = try folder.makeFolder("Atlas/Sources/Core")

        let location = ProjectLocation.locate(from: nested)

        #expect(location.name == "Atlas")
        #expect(location.path == repository.path(percentEncoded: false).dropLast().description)
    }

    @Test func worktreeBelongsToMainRepository() throws {
        let repository = try folder.makeFolder("Atlas")
        _ = try folder.makeFolder("Atlas/.git/worktrees/fix-login")
        let worktree = try folder.makeFolder("worktrees/fix-login")
        let gitDirectory = repository.appending(path: ".git/worktrees/fix-login").path(percentEncoded: false)
        try "gitdir: \(gitDirectory)\n".write(
            to: worktree.appending(path: ".git"),
            atomically: true,
            encoding: .utf8
        )

        #expect(ProjectLocation.locate(from: worktree).name == "Atlas")
    }

    @Test func folderOutsideAnyRepositoryIsItsOwnProject() throws {
        let plain = try folder.makeFolder("Deneme")

        #expect(ProjectLocation.locate(from: plain).name == "Deneme")
    }

    @Test func homeFolderIsTheGeneralProject() {
        let location = ProjectLocation.locate(from: folder.url, home: folder.url)

        #expect(location == ProjectLocation(name: Note.defaultProject, path: nil))
    }
}
