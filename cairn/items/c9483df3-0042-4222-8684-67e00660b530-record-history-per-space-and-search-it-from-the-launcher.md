---
id: c9483df3-0042-4222-8684-67e00660b530
title: Record history per Space and search it from the launcher
type: feature
status: backlog
milestone: v0.2
depends_on:
- 88f87ade-d2e6-4d5b-89e0-a08c24a69cc0
- ea887e3a-8896-47b3-8861-f4b7c50ec79a
created: 2026-09-26
updated: 2026-09-26
priority: p0
effort: m
area: history
---

## Problem

You can find an open page but not one you visited yesterday.

## Proposal

Add a `visits` table (page, url, title, time) written on each committed navigation, never for
private Spaces. The launcher ranks open pages, then history for the current Space by frecency, then
other Spaces' history.

## Acceptance criteria

- [ ] Typing part of a title visited in this Space finds it within 16 ms on a database of 100,000 visits (benchmark test).
- [ ] Private Spaces write no rows, verified by test.
- [ ] Visits older than `history.retain` (default a year, as in `docs/design/config.md`) are pruned at launch.
