---
name: lest
description: Adds notes to Lest, the user's to-do list in the macOS menu bar, and lists, completes or deletes them. Notes are kept with the project they belong to and stay in front of the user. Always use this skill when the user puts something off and does not want it forgotten, in whatever language they say it - "don't forget this", "let's not forget", "add this to my to-do list", "put it on the list", "add it to Lest", "we'll do this later, note it", "remind me to...". Also use it for "what's on my to-do list", "what was pending in this project", "remove this from the list", "mark this note as done". Tracking tasks within a session and writing session notes or decisions to long-term memory are not this skill's job.
---

# Lest

The user works across many projects and many conversations, and forgets the things they said "let's do this later" about. Lest shows those things in the macOS menu bar, together with the project each one belongs to. Notes are added with the `lest` command; the app shows the change right away.

How it differs from a to-do list kept within the session: that list is gone when the session ends, while these notes stay in the menu bar until the user closes them.

## Adding a note

Run the command from the folder of the project being worked on:

```bash
lest add "Verify the Stripe webhook signature; unsigned requests are accepted for now"
```

- The project name comes from the current folder: the name of the git repository, or of the main repository when you are in a worktree.
- If the note is about another project, pass `--project <name>`. `lest projects` lists the existing names; do not invent a second name for a project that already has one.
- If the user listed several separate things, add a note for each.
- Run the command on its own. Chained to another command with `&&` or `||`, it loses the permission to run without asking.
- Only if `lest` is not found, try the full path: `/Applications/Lest.app/Contents/MacOS/Lest add "..."`.

The command writes to `~/Library/Application Support/Lest/notes.json`. If a sandbox blocks that write, run the command again outside the sandbox.

### How to write a note

The note will be read weeks from now, when this conversation is gone. It has to make sense on its own that day:

- Write the note in the language the user is using. Do not translate it.
- Say what is to be done in a sentence or two; add the reason when it helps.
- Name the file, screen or feature instead of pointing at the conversation ("this", "the error above").
- Keep secrets such as passwords and API keys out of notes.

After adding, say so in one line ("Added to Lest: …") in the user's language and get back to the work. Do not add notes the user did not ask for.

## Listing and closing

```bash
lest list --here      # open notes of this project
lest list             # every project
lest list --all       # including completed notes
lest done <id>        # mark as done
lest undone <id>      # reopen
lest rm <id>          # delete
lest show             # open the panel in the menu bar
```

`<id>` is the eight characters in front of each note in the list; its first few characters are enough as long as they are unique. For scripts, use `lest list --json`.

- For questions like "what was pending in this project?", report what `lest list --here` prints.
- For "open the list" or "show my notes", `lest show` opens the panel on screen; it does not take the keyboard, and closes when the user clicks elsewhere.
- When something on the list got done in this session, offer to close it; run `done` once the user agrees.
- Use `rm` only when the user asks you to delete. For finished work use `done`, so the user can undo it.
