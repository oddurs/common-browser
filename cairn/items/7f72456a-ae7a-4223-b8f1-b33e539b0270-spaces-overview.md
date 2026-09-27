---
id: 7f72456a-ae7a-4223-b8f1-b33e539b0270
title: Spaces overview (⌘↑)
type: feature
status: backlog
milestone: v0.2
depends_on:
- 26b831ea-178f-4dfa-a891-2d764e89f326
created: 2026-09-26
updated: 2026-09-26
priority: p1
effort: m
area: chrome
---

## Problem

The strip shows where you are. The overview shows everything and lets you jump.

## Proposal

`⌘↑` shows a grid of Space tiles with live thumbnails of each page layout, the name, the page count
and the shortcut, plus a "New Space" tile. The arrow keys and Return pick a Space, and Esc closes the
overview. The prototype's `SpacesOverview.svelte` is the reference.

## Acceptance criteria

- [ ] Every Space is reachable with the keyboard alone, and focus starts on the current Space.
- [ ] Thumbnails are snapshots taken on switch, not live web views.
- [ ] VoiceOver reads each tile as "name, N pages, Command 2".
