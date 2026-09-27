---
id: ce72c9eb-9162-4289-b917-84f20e6920cf
key: v0.1
title: Browse from the keyboard
type: milestone
status: backlog
created: 2026-09-26
updated: 2026-09-26
priority: p2
due: 2026-11-13
---

## Ships

Browse the web all day from the keyboard. Download the app from GitHub Releases, open it, and it
runs full screen with full-pane pages, a launcher and standard Mac shortcuts. It is configured from
`~/.config/common/common.toml`.

## Done when

- [ ] A person who is not the author installs it from the README and browses for an afternoon without hitting a dead end.
- [ ] Every command is in the menu bar with its shortcut.
- [ ] A mistake in `common.toml` is reported with its line and a suggestion, in the app and by `common config check`.
- [ ] `common-core` builds and passes its tests on macOS, Linux and Windows in CI.

## Explicitly not in this milestone

- Spaces, session restore and history beyond each page's own back list: quitting loses your pages.
- Tiling and the vim layer.
- Signing and notarization: the app is ad-hoc signed, and the README explains the "Open Anyway" step.
