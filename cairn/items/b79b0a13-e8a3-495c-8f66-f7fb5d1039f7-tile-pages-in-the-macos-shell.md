---
id: b79b0a13-e8a3-495c-8f66-f7fb5d1039f7
title: Tile pages in the macOS shell (⌘\)
type: feature
status: backlog
milestone: v0.3
depends_on:
- 656e0ddc-fa0b-4433-af72-ab4f8ed2c66b
created: 2026-09-26
updated: 2026-09-26
priority: p0
effort: m
area: macos
---

## Problem

The layout tree needs rendering.

## Proposal

Render each leaf's web view at the frames the core computes, with a 1-pixel hairline between tiles
and a focus ring on the active tile. `⌘\` cycles layouts: single, then side by side, then grid.
Frame changes animate with the 220 ms move token.

## Acceptance criteria

- [ ] Cycling layouts never reloads a page.
- [ ] Resizing the window keeps the layout's ratios.
- [ ] Clicking a tile focuses it.
