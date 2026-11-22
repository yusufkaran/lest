# Lest

A small macOS menu bar app for the things you tell an AI coding agent to do later. Across many
projects and many conversations, "let's not forget this" is easy to say and easy to lose; Lest
keeps those notes in the menu bar, each with the project it was written for. The name is from
"lest I forget".

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="docs/panel-dark.png">
  <img src="docs/panel-light.png" width="380" alt="The Lest panel in the menu bar: open notes grouped by project">
</picture>

- Click the menu bar icon to see your notes project by project; the number of open notes sits
  next to the icon.
- Tell Claude Code or Codex "don't forget this, add it to my to-do list" and the note is added
  with the `lest` command and shows up in the app right away. The project is the folder (the
  git repository) the command ran in.
- Notes can be added, completed and deleted from the panel too. The chips at the top narrow the
  list down to one project.
- Notes are stored as written, in whatever language you write them.

## Requirements

- macOS 14 or later
- Xcode 16 or later to build it (Swift 6)

## Install

```bash
git clone https://github.com/yusufkaran/lest.git
cd lest
make install
```

This builds the app and installs it as `/Applications/Lest.app`, links the `lest` command into
`~/.local/bin`, connects the coding tools it finds on this Mac, and opens the app. On first
launch the app adds itself to your login items; you can turn that off in the panel's ⋯ menu.

`~/.local/bin` has to be on your `PATH` for the coding tools to find `lest`; the install tells
you when it is not. To link the command into another folder on your `PATH` instead:

```bash
make install COMMAND=/usr/local/bin/lest
```

To update, pull and run `make install` again. To uninstall:

```bash
lest setup --remove                       # remove the files written for the coding tools
pkill -x Lest
rm -r /Applications/Lest.app ~/.local/bin/lest
rm -r ~/Library/Application\ Support/Lest   # your notes; skip this to keep them
```

## Connecting coding tools

```bash
lest setup                   # connect every tool found on this Mac
lest setup codex             # connect just one
lest setup --status          # which ones are connected
lest setup --remove codex    # disconnect
```

Connecting a tool does two things: it installs the skill that teaches the tool when to run
`lest`, and it lets the tool run the command without asking. Lest only writes files of its own
for this and never edits the tool's settings, so disconnecting is deleting those files.

| Tool | Files written |
|---|---|
| Claude Code (`claude`) | `~/.claude/skills/lest/SKILL.md`; the permission is in the skill's `allowed-tools` lines |
| Codex (`codex`) | `~/.agents/skills/lest/SKILL.md` and `~/.codex/rules/lest.rules` |

The permission covers `add`, `list`, `projects`, `done`, `undone` and `show`; `lest rm` asks
every time. When the app is updated, it brings the files of connected tools up to date itself.

Claude Code asks before using a skill that carries permissions. Choose "don't ask again" when
it first asks, or add `Skill(lest)` to your allow list, and it will not ask again. Codex reads
its rules at startup, so restart sessions that were open when you connected it.

For any other tool, the skill is in this repository: `skill/lest/SKILL.md`.

## The command

```bash
lest add "Verify the Stripe webhook signature"   # project: the current folder
lest add "Update the footer" --project Landing
lest list --here                                 # open notes of this project
lest list --all                                  # including completed notes
lest done 3f2a                                   # the first characters of the id are enough
lest rm 3f2a
lest projects
lest show                                        # opens the panel on screen
```

The app's executable is this command as well: when its first argument is a command it runs
that and exits, otherwise it starts as the menu bar app.

## Data

Notes live in `~/Library/Application Support/Lest/notes.json`. The app and the command share
that file; every change is made under a file lock, and the app watches the folder and shows
changes by itself. The `LEST_DIR` environment variable points both at another folder, which is
handy for experiments.

## Development

```bash
make test       # unit tests
make snapshot   # draws the panel with sample notes into build/snapshots
make icons      # compiles the SVG files in Resources/Phosphor into Swift
make skill      # compiles skill/lest/SKILL.md into Swift
make app-icon   # regenerates Resources/AppIcon.icns
```

There are two ways to look at an interface change: `make snapshot` draws the panel off screen,
and `lest show` opens the real panel of the running app.

- `Sources/LestCore`: the note model, the file store, project detection, the command line and
  the tool connections
- `Sources/Lest`: the menu bar item and the panel window (AppKit), and the panel's contents
  (SwiftUI)
- `Resources/Phosphor`: the icons in the panel ([Phosphor Icons](https://phosphoricons.com),
  MIT). To add one, put its SVG file there and run `make icons`.
- `skill/lest/SKILL.md`: when and how a connected tool adds a note. Run `make skill` after
  editing it.

To support another coding tool, add a case to `Sources/LestCore/Connections/CodingTool.swift`:
it names the tool's settings folder, where its skill goes and the files to write.
