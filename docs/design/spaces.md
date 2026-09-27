# Spaces and history

A Space is the one idea that replaces workspaces, sessions and cookie jars. It holds pages, their
layout, their logins and their history. Spaces sit in a line from left to right, and the browser
always shows you which one you are in.

The prototype in [`prototype/`](../../prototype/README.md) implements this model: the capsule, the
strip, the overview, archive and restore.

## What folds into a Space

| Before | Now | What you notice |
| --- | --- | --- |
| Workspaces 1–9 | Spaces, in order, created when needed | No empty numbered slots. The line is exactly as long as your work. |
| Sessions | A Space's own history: snapshots and the page tree | "Put Dev back how it was on Tuesday" is something a Space can do. |
| Cookie jars | Each Space has its own logins; `jar = "work"` lets Spaces share | Log in to two accounts in two Spaces. |
| Private workspace | A private Space: memory-only logins, no history, red dot | It remembers nothing. |
| Fork | Duplicate Space: copies the pages, shares the logins | A tangent gets its own Space without cluttering the original. |

## Rules

- **A Space exists while it has pages.** ⌘N adds one at the end of the line and opens the
  launcher in it. ⇧⌘N makes a private one.
- **Names come from the pages.** A new Space takes the name of its first site ("tessera") until it
  is renamed in the overview or in `common.toml`.
- **Every Space gets a colour.** Six quiet tints are assigned in turn: sage, blue, sand, clay, plum,
  slate. `tint =` overrides it. The colour marks the capsule, the strip and the Window menu, nothing
  else.
- **Order is position.** ⌘1–9 jump to the first nine. ⇧⌘[ and ⇧⌘] step along the line. Drag in the
  overview to reorder.
- **Pages move, Spaces stay.** ⇧⌘1–9 sends the focused page to that Space, keeping it loaded, and
  in the overview a page can be dragged to another Space.

## Lifecycle

1. **Create.** ⌘N adds a Space at the end of the line and opens the launcher in it. ⇧⌘N makes a
   private one.
2. **Name.** A new Space takes its first site's name until renamed.
3. **Colour.** Each Space gets the next of the six tints.
4. **Archive.** Closing a Space's last page archives it with that page. Nothing is deleted.
5. **Restore.** Archived Spaces wait under "Recently closed" in the overview. One click brings one
   back at the end of the line.
6. **Private ends.** A private Space is discarded when its last page closes: no archive, no
   history.

Moving a Space's only page to another Space removes the emptied Space without archiving a copy.

## Knowing where you are

Most of the time you should not have to think about Spaces. When you do, the answer is one glance,
one keystroke or one gesture away, and each depth shows a little more.

| Depth | What you do | What you see |
| --- | --- | --- |
| Glance | Pointer to the top edge | Capsule: colour dot, name, "2 of 4", current site |
| Switch | ⌘1–9 or ⇧⌘[ ] | Strip of Space tiles drawn from real layouts; a frame glides to where you landed; fades after 1.1s |
| Overview | ⌘↑ | Every Space large, with page count and shared logins; New Space; recently closed. Pick, rename, reorder, move pages. |

The Window menu also lists every Space with a tick beside the current one.

## Keys

| Keys | Does |
| --- | --- |
| ⌘N | New Space at the end of the line |
| ⇧⌘N | New private Space |
| ⌘1 – ⌘9 | Go to a Space by position |
| ⇧⌘[  ⇧⌘] | Previous or next Space |
| ⇧⌘1 – ⇧⌘9 | Send the focused page to a Space |
| ⌘↑ | All Spaces |
| ⌘W | Close the page; closing the last one archives the Space |

## History works like git

| Git | Common Browser | What you get |
| --- | --- | --- |
| commit | Snapshot: pages, layout, scroll positions, taken on every Space switch and after idle | Put a Space back as it was on Tuesday (`:log`) |
| branch | A Space's line of snapshots | Each Space has its own past |
| worktree | The Space shown in the window | Several Spaces open at once |
| stash | Archive | Close freely, lose nothing |
| branch from here | Duplicate Space | A tangent without cluttering the original |
| cherry-pick | Send a page to another Space | Move one find to where it belongs |
| reflog | Every visit and close, kept for `history.retain` | Reopen anything, not only the last page |
| commit graph | Page tree: going back then clicking elsewhere starts a branch | Forward history is never destroyed |

## Data model

Visits are written once and never changed; everything else points at them. Everything lives in one
SQLite file, `common.db`, in the platform's data directory (`~/Library/Application Support/Common/`
on macOS).

```
Visit     id, url, title, at, page, space, prev (same page), opener (branch point), via
Site      url, title, first_seen, last_seen, visits, frecency
Page      id, space, head → Visit, scroll
Space     id, name, tint, jar, position, layout, head → Snapshot, archived_at, private
Snapshot  id, space, parent → Snapshot, at, layout, pages [{ head, scroll }]
Jar       id, kind (persistent | memory)
```

Back and forward follow `prev`; forward asks which branch only when there is more than one.
Snapshots hold addresses and positions, never page contents, so they cost almost nothing.

## In common.toml

Starting Spaces are declared in the file. Everything after that, the pages you open and the history
they build, lives in the database.

```toml
# Spaces open in this order. Colour and jar are optional.
[[space]]
name = "reading"
open = ["notes.example.org"]

[[space]]
name = "dev"
tint = "blue"   # sage blue sand clay plum slate
jar  = "work"   # share logins with other Spaces in this jar
open = ["code.example.dev/common/browser/pulls", "localhost:5173"]
```

## Decided

- One noun, Space, for what used to be three ideas.
- No fixed slots; the line is exactly as long as your work.
- Each Space has its own logins by default; sharing is opt-in by jar name.
- Private is a kind of Space, not a separate mode.
- A duplicated Space shares its source's jar; `--fresh` gives it an empty one.
- The database is the source of truth; `common space export` writes a Space as TOML for dotfiles.
- Starting Spaces are declared as `[[space]]` in `common.toml`.

## Where it is on the roadmap

| Part | Item | Milestone |
| --- | --- | --- |
| Separate data stores per Space | `6e0024ef` (spike) | v0.2 |
| Spaces and pages in SQLite | `ea887e3a` | v0.2 |
| New and private Space | `26b831ea` | v0.2 |
| Switching and the strip | `1a18d09b` | v0.2 |
| Overview | `7f72456a` | v0.2 |
| Names, tints, `[[space]]` | `d865dd06` | v0.2 |
| Jars | `a37a5963` | v0.2 |
| Archive and restore | `ef5185b9` | v0.2 |
| History per Space | `c9483df3` | v0.2 |
| `common space list` and `export` | `7ff3fe9f` | v0.2 |
| Page tree | `26445f81` | v0.3 |
| Duplicate (fork) a Space | `9a298aac` | v0.3 |
| Snapshots | `d7873924` | v0.3 |
