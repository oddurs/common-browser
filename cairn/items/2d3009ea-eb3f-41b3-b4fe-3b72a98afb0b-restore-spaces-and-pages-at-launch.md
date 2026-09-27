---
id: 2d3009ea-eb3f-41b3-b4fe-3b72a98afb0b
title: Restore Spaces and pages at launch
type: feature
status: backlog
milestone: v0.2
depends_on:
- ea887e3a-8896-47b3-8861-f4b7c50ec79a
created: 2026-09-26
updated: 2026-09-26
priority: p0
effort: m
area: history
---

## Problem

Quitting loses everything in v0.1.

## Proposal

At launch, recreate every Space and page from the database. Only the visible page loads; the
others load when first shown.

## Acceptance criteria

- [ ] Quit with 3 Spaces and 20 pages, relaunch: all are back in order, and exactly one page has loaded.
- [ ] A crash (`kill -9`) loses at most the last second of changes.
- [ ] Private Spaces are not restored.
