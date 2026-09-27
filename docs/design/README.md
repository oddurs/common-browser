# Design

The approved design of Common Browser: what it looks like, how it is driven, and how Spaces and
history work. The code and the roadmap follow this spec. When the two disagree, fix whichever is
wrong in a pull request that says so.

| File | Covers |
| --- | --- |
| [interface.md](interface.md) | Surfaces, materials, type, colour, motion, the keymap, the vim layer, the launcher, link hints, tiling, accessibility |
| [spaces.md](spaces.md) | The Space model, its lifecycle, knowing where you are, history as git, the data model |
| [config.md](config.md) | Every key `common.toml` has or is planned to have |
| [architecture.md](architecture.md) | How the pieces fit, performance budgets, privacy and security |
| [open-questions.md](open-questions.md) | What is still undecided, each with a recommendation |

For what is built and when, see [ROADMAP.md](../../ROADMAP.md). The web prototype in
[`prototype/`](../../prototype/README.md) shows most of this spec working.

## What it is

Common Browser is an open-source browser, built for macOS first. It opens fullscreen, is driven
from the keyboard with standard Mac shortcuts, and keeps every setting in one file,
`common.toml`. It runs on the system's WebKit, so scrolling feels exactly like Safari's. Pages tile
side by side, and Spaces keep separate sets of pages, logins and history, lined up where you can
always see them.

Positioning: a fast, fullscreen browser you drive from the keyboard. Vim keys if you want them.

## Principles

When two collide, the higher one wins.

1. **The page owns the screen.** Fullscreen is home. Chrome appears when called and leaves on its
   own; the page never shifts.
2. **The file is the settings screen.** No settings window. `common.toml` reloads on save and
   reports mistakes by line.
3. **Never touch the scroll.** Momentum, rubber-banding and gestures come from WebKit untouched.
4. **Keyboard first, not vim first.** Standard Mac shortcuts by default; vim keys are one line in
   the config. Everything is also in the menu bar.
5. **Native where it counts.** Real macOS fullscreen, menus, materials, light and dark.
6. **One quiet piece of chrome at a time.** System font everywhere; monospace only for key hints,
   code and config. The accent colour is rare.
7. **Themes are data.** A theme is a small file of colour tokens that every surface reads.

The look is minimal, refined and native to macOS, with a style of its own. It borrows Omarchy's
spirit (keyboard, tiling, a config file, strong themes) but never looks like a terminal. That
means no monospace everywhere, no rainbow of status colours, and nothing on screen that isn't
needed right now.

## Not the goal

- A browser engine of our own, or Chromium. WebKit is the reason scrolling is right.
- Chrome or Firefox extensions. Userscripts and content-blocking lists cover the need.
- A settings window, accounts, sync servers, telemetry or built-in AI.
- A tab strip. Pages and Spaces replace it.

## Glossary

| Term | Meaning |
| --- | --- |
| Space | A set of pages with their layout, logins and history. Spaces sit in a line. |
| Page | One web page in a pane. A Space shows one or more pages tiled. |
| Capsule | The small floating bar that appears at the top edge: Space, position, address. |
| Launcher | The one field for addresses, searches, open pages and commands (⌘L). |
| Strip | The row of Space tiles shown briefly when you switch Space. |
| Overview | All Spaces side by side, large (⌘↑). |
| Link hints | Letter labels on every link on screen, typed to follow (⌘J). |
| Jar | The store of cookies and site data. Each Space has its own unless it shares one. |
| Snapshot | A saved state of a Space: its pages, layout and scroll positions. |
| Page tree | History kept as a tree, so going back and clicking elsewhere never loses a branch. |

## Where this came from

This spec was approved on 2026-09-26. It was written first as a set of pages outside the
repository: a project plan, a detailed breakdown, and a Spaces concept with a working demo. Those
pages are gone, so their text was restored here from the original sources, section by section.
Keeping it in the repository means it is versioned and reviewed like the code, and cannot vanish
again.

Decisions made while building, after the approval, are applied here rather than left stale:

| Approved | Now | Why |
| --- | --- | --- |
| macOS only | macOS first, on a Rust core that Linux and Windows shells will share | Decided when the repository was started: a browser has to run everywhere to last |
| A pure-Swift core module (`CommonCore`) | A Rust crate, `common-core`, reaching Swift through UniFFI (`common-ffi`) | The core has to serve three shells; see the bridge spike, `5ad0243e` |
| `launcher.search` for the default search | `search.engine` | Shipped that way in v0.1 (#4). `launcher.bangs` stays under `[launcher]` |
| `history.sqlite` | `common.db` | Named in the Spaces storage item, `ea887e3a`; it holds more than history |
| No item for snapshots | Item `d7873924` in v0.3 | The roadmap missed it; added with this spec |
