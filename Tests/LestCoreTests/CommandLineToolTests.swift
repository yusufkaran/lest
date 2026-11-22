import Foundation
import Testing
@testable import LestCore

struct CommandLineToolTests {
    let folder: TemporaryFolder
    let store: NoteStore
    let project: URL
    let home: URL
    let connections: ToolConnections
    let tool: CommandLineTool

    init() throws {
        folder = try TemporaryFolder()
        store = NoteStore(directory: folder.url.appending(path: "store", directoryHint: .isDirectory))
        project = try folder.makeFolder("Atlas")
        _ = try folder.makeFolder("Atlas/.git")
        home = try folder.makeFolder("home")
        connections = ToolConnections(home: home)
        tool = CommandLineTool(store: store, workingDirectory: project, connections: connections)
    }

    @Test func addUsesTheProjectOfTheCurrentFolder() throws {
        let output = tool.run(["add", "Rate limit için retry ekle"])

        let note = try #require(try store.load().first)
        #expect(output.exitCode == 0)
        #expect(output.text == "Added [\(note.shortID)] Atlas: Rate limit için retry ekle")
        #expect(note.path == project.path(percentEncoded: false).dropLast().description)
    }

    @Test func addJoinsUnquotedWords() throws {
        _ = tool.run(["add", "README", "yaz"])

        #expect(try store.load().first?.text == "README yaz")
    }

    @Test func addKeepsTextThatStartsWithDashes() throws {
        let output = tool.run(["add", "--verbose bayrağını kaldır"])

        #expect(output.exitCode == 0)
        #expect(try store.load().first?.text == "--verbose bayrağını kaldır")
    }

    @Test func addReusesTheSpellingOfAnExistingProject() throws {
        _ = tool.run(["add", "ilk", "--project", "Website"])
        _ = tool.run(["add", "ikinci", "-p", "website"])

        let notes = try store.load()
        #expect(notes.map(\.project) == ["Website", "Website"])
        #expect(notes.allSatisfy { $0.path == nil })
    }

    @Test func addRejectsEmptyText() throws {
        let output = tool.run(["add", "   "])

        #expect(output.exitCode == 2)
        #expect(try store.load().isEmpty)
    }

    @Test func listGroupsOpenNotesByProject() throws {
        _ = tool.run(["add", "retry ekle"])
        _ = tool.run(["add", "footer düzelt", "--project", "Landing"])
        let notes = try store.load()

        let output = tool.run(["list"])

        #expect(output.text == """
            Landing (1)
              \(notes[1].shortID)  footer düzelt
            Atlas (1)
              \(notes[0].shortID)  retry ekle
            """)
    }

    @Test func listHereShowsOnlyTheCurrentProject() throws {
        _ = tool.run(["add", "retry ekle"])
        _ = tool.run(["add", "footer düzelt", "--project", "Landing"])

        let output = tool.run(["list", "--here"])

        #expect(output.text.contains("retry ekle"))
        #expect(!output.text.contains("footer düzelt"))
    }

    @Test func listHidesDoneNotesUnlessAsked() throws {
        _ = tool.run(["add", "retry ekle"])
        let id = try #require(try store.load().first?.shortID)
        _ = tool.run(["done", id])

        #expect(tool.run(["list"]).text == "No open notes.")
        #expect(tool.run(["list", "--all"]).text.contains("✓ retry ekle"))
    }

    @Test func listCanPrintJSON() throws {
        _ = tool.run(["add", "retry ekle"])

        let output = tool.run(["list", "--json"])

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode([Note].self, from: Data(output.text.utf8))
        #expect(decoded.map(\.text) == ["retry ekle"])
    }

    @Test func doneAndUndoneAcceptAnIdentifierPrefix() throws {
        _ = tool.run(["add", "retry ekle"])
        let id = try #require(try store.load().first?.id)

        #expect(tool.run(["done", String(id.prefix(5)).uppercased()]).exitCode == 0)
        #expect(try store.load().first?.isDone == true)

        #expect(tool.run(["undone", String(id.prefix(5))]).exitCode == 0)
        #expect(try store.load().first?.isDone == false)
    }

    @Test func removeDeletesTheNote() throws {
        _ = tool.run(["add", "retry ekle"])
        let id = try #require(try store.load().first?.shortID)

        let output = tool.run(["rm", id])

        #expect(output.text == "Deleted [\(id)] Atlas: retry ekle")
        #expect(try store.load().isEmpty)
    }

    @Test func unknownIdentifierFailsWithoutChangingAnything() throws {
        _ = tool.run(["add", "retry ekle"])

        let output = tool.run(["done", "zzzz"])

        #expect(output.exitCode == 1)
        #expect(try store.load().first?.isDone == false)
    }

    @Test func ambiguousIdentifierIsRejected() throws {
        try store.update { notes in
            notes.append(Note(id: "abc111", text: "bir", project: "Alfa"))
            notes.append(Note(id: "abc222", text: "iki", project: "Alfa"))
        }

        let output = tool.run(["rm", "abc"])

        #expect(output.exitCode == 1)
        #expect(try store.load().count == 2)
    }

    @Test func showOpensThePanelOfTheRunningApp() {
        let tool = CommandLineTool(store: store, workingDirectory: project, connections: connections) { true }

        #expect(tool.run(["show"]) == CommandLineTool.Output(text: "Panel opened.", exitCode: 0))
    }

    @Test func showFailsWhenTheAppIsNotRunning() {
        let tool = CommandLineTool(store: store, workingDirectory: project, connections: connections) { false }

        #expect(tool.run(["show"]).exitCode == 1)
    }

    @Test func setupConnectsEveryToolFoundOnThisMac() throws {
        _ = try folder.makeFolder("home/.claude")
        _ = try folder.makeFolder("home/.codex")

        let output = tool.run(["setup"])

        #expect(output.exitCode == 0)
        #expect(output.text == """
            Claude Code connected:
              ~/.claude/skills/lest/SKILL.md
            Codex connected:
              ~/.agents/skills/lest/SKILL.md
              ~/.codex/rules/lest.rules
            Codex sessions that are already open pick this up after a restart.
            """)
        #expect(connections.status(of: .claudeCode) == .connected)
        #expect(connections.status(of: .codex) == .connected)
    }

    @Test func setupLeavesOutToolsThatAreNotInstalled() throws {
        _ = try folder.makeFolder("home/.claude")

        let output = tool.run(["setup"])

        #expect(output.text == "Claude Code connected:\n  ~/.claude/skills/lest/SKILL.md")
        #expect(connections.status(of: .codex) == .notInstalled)
    }

    @Test func setupFailsForANamedToolThatIsNotInstalled() {
        let output = tool.run(["setup", "codex"])

        #expect(output == CommandLineTool.Output(text: "Codex was not found on this Mac.", exitCode: 1))
    }

    @Test func setupFailsWhenThereIsNothingToConnect() {
        #expect(tool.run(["setup"]).exitCode == 1)
    }

    @Test func setupRejectsAnUnknownTool() {
        #expect(tool.run(["setup", "notepad"]).exitCode == 2)
    }

    @Test func setupStatusReportsEachTool() throws {
        _ = try folder.makeFolder("home/.claude")
        _ = tool.run(["setup", "claude"])

        let output = tool.run(["setup", "--status"])

        #expect(output == CommandLineTool.Output(text: "Claude Code: connected\nCodex: not installed", exitCode: 0))
    }

    @Test func setupRemoveDeletesTheFilesOfTheNamedTool() throws {
        _ = try folder.makeFolder("home/.claude")
        _ = try folder.makeFolder("home/.codex")
        _ = tool.run(["setup"])

        let output = tool.run(["setup", "--remove", "claude"])

        #expect(output.text == "Claude Code disconnected:\n  ~/.claude/skills/lest/SKILL.md")
        #expect(connections.status(of: .claudeCode) == .notConnected)
        #expect(connections.status(of: .codex) == .connected)
        #expect(tool.run(["setup", "--remove", "claude"]).text == "Claude Code is not connected.")
    }

    @Test func unknownOptionShowsUsage() {
        let output = tool.run(["list", "--nope"])

        #expect(output.exitCode == 2)
        #expect(output.text.contains("Usage:"))
    }
}
