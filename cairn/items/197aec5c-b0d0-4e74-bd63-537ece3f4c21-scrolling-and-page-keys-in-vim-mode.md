---
id: 197aec5c-b0d0-4e74-bd63-537ece3f4c21
title: Scrolling and page keys in vim mode
type: feature
status: backlog
milestone: v0.3
depends_on:
- d3d5b112-7500-4386-a83a-066634647e1d
created: 2026-09-26
updated: 2026-09-26
priority: p1
effort: s
area: input
---

## Problem

Reading needs to work without modifiers.

## Proposal

The keys are `j` and `k` (scroll), `d` and `u` (half page), `gg` and `G` (top and bottom), `H` and
`L` (back and forward), `r` (reload), `x` (close page), `o` (launcher) and `yy` (copy address).
Scrolling uses WebKit's native smooth scrolling, so it matches trackpad physics.

## Acceptance criteria

- [ ] Each key is listed in the ⌘/ overlay when vim mode is on.
- [ ] Scrolling targets the element under focus, not always the document (for example, a scrollable sidebar).
