import Foundation
import Testing
@testable import LestCore

struct ToolConnectionsTests {
    let folder: TemporaryFolder
    let home: URL
    let connections: ToolConnections

    init() throws {
        folder = try TemporaryFolder()
        home = try folder.makeFolder("home")
        connections = ToolConnections(home: home)
    }

    @Test func aToolThatIsNotOnThisMacIsNotInstalled() {
        #expect(connections.status(of: .claudeCode) == .notInstalled)
    }

    @Test func anInstalledToolStartsOutNotConnected() throws {
        _ = try folder.makeFolder("home/.codex")

        #expect(connections.status(of: .codex) == .notConnected)
    }

    @Test func connectingClaudeCodeWritesTheSkillWithItsPermission() throws {
        try connections.connect(.claudeCode)

        let skill = try read(".claude/skills/lest/SKILL.md")
        let parts = skill.components(separatedBy: "\n---\n")
        let frontMatter = try #require(parts.first)
        #expect(parts.count == 2)
        #expect(frontMatter.hasPrefix("---\nname: lest\ndescription: "))
        #expect(frontMatter.hasSuffix("""
            allowed-tools:
              - Bash(lest add *)
              - Bash(lest list *)
              - Bash(lest projects *)
              - Bash(lest done *)
              - Bash(lest undone *)
              - Bash(lest show *)
            """))
        #expect(parts.last == SkillText.markdown.components(separatedBy: "\n---\n").last)
        #expect(connections.status(of: .claudeCode) == .connected)
    }

    @Test func connectingCodexWritesTheSkillAndARuleForTheCommand() throws {
        try connections.connect(.codex)

        #expect(try read(".agents/skills/lest/SKILL.md") == SkillText.markdown)
        let rules = try read(".codex/rules/lest.rules")
        #expect(rules.contains(#"pattern = ["lest", ["add", "list", "projects", "done", "undone", "show"]],"#))
        #expect(rules.contains(#"decision = "allow","#))
        #expect(connections.status(of: .codex) == .connected)
    }

    @Test func aFileLeftByAnEarlierVersionMakesTheToolOutdatedUntilRefreshed() throws {
        try connections.connect(.codex)
        try write("an older rule", to: ".codex/rules/lest.rules")
        #expect(connections.status(of: .codex) == .outdated)

        try connections.refresh()

        #expect(connections.status(of: .codex) == .connected)
    }

    @Test func refreshDoesNotConnectAToolByItself() throws {
        _ = try folder.makeFolder("home/.claude")

        try connections.refresh()

        #expect(connections.status(of: .claudeCode) == .notConnected)
    }

    @Test func disconnectingRemovesOnlyTheFilesLestWrote() throws {
        try connections.connect(.codex)
        try write("someone else's rule", to: ".codex/rules/default.rules")
        try write("someone else's skill", to: ".agents/skills/other/SKILL.md")

        let removed = try connections.disconnect(.codex)

        #expect(removed.map(\.lastPathComponent) == ["SKILL.md", "lest.rules"])
        #expect(!exists(".agents/skills/lest"))
        #expect(!exists(".codex/rules/lest.rules"))
        #expect(exists(".codex/rules/default.rules"))
        #expect(exists(".agents/skills/other/SKILL.md"))
        #expect(connections.status(of: .codex) == .notConnected)
    }

    @Test func disconnectingKeepsASkillFolderSomethingElseWasPutIn() throws {
        try connections.connect(.claudeCode)
        try write("my own notes", to: ".claude/skills/lest/notes.md")

        try connections.disconnect(.claudeCode)

        #expect(!exists(".claude/skills/lest/SKILL.md"))
        #expect(exists(".claude/skills/lest/notes.md"))
    }

    /// The skill is compiled in from a generated file; this fails when `make skill` was not
    /// run after editing skill/lest/SKILL.md.
    @Test func theCompiledInSkillMatchesTheSkillFile() throws {
        let repository = URL(filePath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let file = repository.appending(path: "skill/lest/SKILL.md")

        #expect(try String(contentsOf: file, encoding: .utf8) == SkillText.markdown)
    }

    private func read(_ path: String) throws -> String {
        try String(contentsOf: home.appending(path: path), encoding: .utf8)
    }

    private func write(_ text: String, to path: String) throws {
        let file = home.appending(path: path)
        try FileManager.default.createDirectory(at: file.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(text.utf8).write(to: file)
    }

    private func exists(_ path: String) -> Bool {
        FileManager.default.fileExists(atPath: home.appending(path: path).path(percentEncoded: false))
    }
}
