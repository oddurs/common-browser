---
id: b99f0ee3-b421-4242-93c1-693f5a31de2d
title: Graphite and paper themes following system appearance
type: feature
status: planned
milestone: v0.1
depends_on:
- 266d12d4-7099-406d-9c75-4e60a0fd8151
created: 2026-09-26
updated: 2026-09-26
priority: p1
effort: s
area: chrome
---

## Problem

The config promises themes, and the browser's own UI has to match light and dark mode.

## Proposal

Define the themes as data in `common-core`, so every shell shares them: graphite (dark), paper
(light) and an accent colour (default copper). `theme` applies in dark mode and `theme_light` in
light mode. The UI uses the system font everywhere, and mono only for key hints and config text.

## Acceptance criteria

- [ ] Switching system appearance switches the theme within one frame.
- [ ] `accent = "#3b82f6"` recolours the focus ring and progress line.
- [ ] An unknown theme name is a config error listing the known names.
