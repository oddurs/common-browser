---
id: 59802bd4-2d70-4bfd-97a3-02c9a4e55095
title: Move focus and swap tiles from the keyboard
type: feature
status: backlog
milestone: v0.3
depends_on:
- b79b0a13-e8a3-495c-8f66-f7fb5d1039f7
created: 2026-09-26
updated: 2026-09-26
priority: p0
effort: s
area: input
---

## Problem

Tiling without keyboard movement is only half a feature.

## Proposal

`⌥⌘` plus an arrow moves focus in that direction, and `⇧⌥⌘` plus an arrow swaps the focused tile
with its neighbour. In the single layout, `⌥⌘←` and `⌥⌘→` keep moving between pages, as in v0.1.

## Acceptance criteria

- [ ] Every tiling action is in the menu bar with its shortcut.
- [ ] Focus moves never steal focus from a text field without the modifier.
