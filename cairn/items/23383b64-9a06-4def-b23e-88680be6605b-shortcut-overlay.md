---
id: 23383b64-9a06-4def-b23e-88680be6605b
title: Shortcut overlay (⌘/)
type: feature
status: backlog
milestone: v0.2
depends_on:
- 355bebe7-8757-4197-8c01-df92624fc0d5
created: 2026-09-26
updated: 2026-09-26
priority: p2
effort: s
area: input
---

## Problem

The menu bar lists everything, but a glanceable sheet is faster to learn from.

## Proposal

`⌘/` shows an overlay of every command and its shortcut, generated from the command registry and
grouped by menu.

## Acceptance criteria

- [ ] The overlay and the menu bar come from the same table (a test compares them).
- [ ] Esc or `⌘/` closes it.
