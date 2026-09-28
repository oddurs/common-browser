# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `docs/config.md`, describing every setting, and install steps in the README.
- The launcher: ⌘L over the page, or ⌘T on a new page. Type an address or words to search, or pick
  an open page with the arrow keys; Return goes, Esc puts focus back where it was.
- Links that open a new window, and `window.open`, open a page right beside the page that opened
  it; `window.close()` closes it and returns to its opener, so sign-in pop-ups complete.
- `common.toml` is read at launch: `home`, `window.start` and `search.engine` apply, and a mistake
  shows a banner naming its line while every other key still applies. ⌘, opens the file, first
  writing one with every setting commented out.
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
- Downloads: files a page cannot show, attachments and `<a download>` links save to `~/Downloads`
  without overwriting (`name 2.ext`), quarantined for Gatekeeper, with a notice while they run.
  A failed download leaves no partial file and says why. ⌥⌘L shows the latest one in Finder.
- Video players' full-screen buttons work: pages may show an element full screen.
- Back (⌘[), Forward (⌘]), Reload (⌘R) and Stop (⌘.) act on the page wherever focus is, and their
  menu items are disabled when they cannot act. ⇧⌘C copies the page's address. Two-finger swipes
  go back and forward.
