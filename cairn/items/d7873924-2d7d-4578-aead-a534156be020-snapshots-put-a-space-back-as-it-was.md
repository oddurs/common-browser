---
id: d7873924-2d7d-4578-aead-a534156be020
title: 'Snapshots: put a Space back as it was'
type: feature
status: backlog
milestone: v0.3
depends_on:
- 26445f81-6c72-494f-8dc3-1dbc8a9ca90b
- 656e0ddc-fa0b-4433-af72-ab4f8ed2c66b
- ea887e3a-8896-47b3-8861-f4b7c50ec79a
created: 2026-09-27
updated: 2026-09-27
priority: p2
effort: m
area: history
---

## Problem

The approved Spaces design treats a Space's history like git: a Space should be able to go back to how it was on Tuesday, pages and layout included. The page tree keeps each page's branches, but nothing records the Space as a whole.

## Proposal

A snapshot records a Space's pages (each page's head visit and scroll position) and its layout, with a parent snapshot, as in `docs/design/spaces.md`. Snapshots hold addresses and positions, never page contents. They are taken on every Space switch and after the Space has been idle a while. `[history] snapshot = "on-switch" | "idle" | "manual"` in `common.toml` chooses when. A launcher command, `:log`, lists a Space's snapshots newest first. Choosing one restores those pages and that layout into the Space; the current state is snapshotted first, so a restore can be undone the same way. Private Spaces take no snapshots.

## Acceptance criteria

- [ ] Switching away from a Space records a snapshot of its pages, layout and scroll positions, covered by a core test on the model.
- [ ] Restoring a snapshot brings back its pages in order with their layout, and the state before the restore is itself a snapshot, so it can be undone.
- [ ] A private Space records no snapshots (tested).
- [ ] `[history] snapshot = "manual"` stops automatic snapshots, and `:log` still lists the manual ones.
