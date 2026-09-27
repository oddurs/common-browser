# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- A menu bar that lists every command with its shortcut, including standard editing (copy, paste,
  undo) inside pages.
- `common config check [--path FILE]` reports each error in `common.toml` as
  `FILE:LINE:COL: MESSAGE` and exits 1 if there are any.
- Pages: ⌘T opens one, ⌘W closes the one on screen, ⌥⌘← and ⌥⌘→ move between them. One page fills
  the window at a time, and hidden pages keep their state.
- The window remembers its size and position between launches, and one saved on a display that is
  gone reopens on a screen that is there.
- JavaScript `alert`, `confirm` and `prompt` appear as sheets on the window, and file inputs open
  a file panel. From a page's second dialog on, the sheet offers to block further dialogs from it.
- Find in page: ⌘F opens a find field at the top of the window that highlights every match and
  shows "3 of 12". ⌘G and ⇧⌘G (or Return and Shift-Return) move between matches, and Esc closes it.
