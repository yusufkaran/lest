import Foundation

/// A coding tool Lest can connect to.
///
/// Connecting a tool means writing the files that teach it when to run `lest` and let it do so
/// without asking. Every one of them is a file of Lest's own; the tool's settings are never
/// edited, so disconnecting is deleting those files again.
public enum CodingTool: String, CaseIterable, Sendable {
    case claudeCode = "claude"
    case codex

    public var name: String {
        switch self {
        case .claudeCode: "Claude Code"
        case .codex: "Codex"
        }
    }

    /// The `lest` commands a connected tool may run without asking. `rm` is left out on
    /// purpose: deleting a note still asks.
    static let unpromptedCommands = ["add", "list", "projects", "done", "undone", "show"]

    /// The folder whose presence shows the tool is installed.
    func settingsFolder(in home: URL) -> URL {
        switch self {
        case .claudeCode: home.appending(path: ".claude", directoryHint: .isDirectory)
        case .codex: home.appending(path: ".codex", directoryHint: .isDirectory)
        }
    }

    /// The folder Lest creates for its skill, removed again when the tool is disconnected.
    func skillFolder(in home: URL) -> URL {
        switch self {
        case .claudeCode: home.appending(path: ".claude/skills/lest", directoryHint: .isDirectory)
        // Codex reads personal skills from the folder shared by tools that follow the
        // Agent Skills convention, not from its own settings folder.
        case .codex: home.appending(path: ".agents/skills/lest", directoryHint: .isDirectory)
        }
    }

    func files(in home: URL) -> [ManagedFile] {
        let skill = skillFolder(in: home).appending(path: "SKILL.md")
        switch self {
        case .claudeCode:
            return [ManagedFile(url: skill, contents: Self.claudeSkill)]
        case .codex:
            return [
                ManagedFile(url: skill, contents: SkillText.markdown),
                ManagedFile(url: settingsFolder(in: home).appending(path: "rules/lest.rules"), contents: Self.codexRules),
            ]
        }
    }

    /// Claude Code takes the permission from the skill itself: the commands listed under
    /// `allowed-tools` run without asking while the skill is in use. Because the skill grants
    /// something, Claude Code asks before using it until the user allows `Skill(lest)`.
    private static var claudeSkill: String {
        let grant = ["allowed-tools:"] + unpromptedCommands.map { "  - Bash(lest \($0) *)" }
        // The text opens with "---", so the first "---" on a line of its own after that closes
        // the front matter.
        guard let closing = SkillText.markdown.range(of: "\n---\n") else { return SkillText.markdown }
        return SkillText.markdown.replacingCharacters(in: closing, with: "\n\(grant.joined(separator: "\n"))\n---\n")
    }

    /// Codex keeps commands inside a sandbox that cannot write to the notes folder, and asks
    /// before running one outside it. A rules file of Lest's own lifts both for `lest`.
    private static var codexRules: String {
        let commands = unpromptedCommands.map { "\"\($0)\"" }.joined(separator: ", ")
        return """
            # Written by Lest, the menu bar to-do list. `lest setup --remove codex` deletes this file.
            #
            # Lets Codex run `lest` outside the sandbox without asking: notes are saved in
            # ~/Library/Application Support/Lest, which the sandbox cannot write to.
            # `lest rm` is left out on purpose, so deleting a note still asks.
            prefix_rule(
                pattern = ["lest", [\(commands)]],
                decision = "allow",
                justification = "Lest saves notes outside the workspace.",
                match = [
                    "lest add footer",
                    "lest list --here",
                ],
                not_match = [
                    "lest rm 3f2a",
                ],
            )

            """
    }
}
