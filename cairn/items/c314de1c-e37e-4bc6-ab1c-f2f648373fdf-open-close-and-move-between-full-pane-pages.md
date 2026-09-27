---
id: c314de1c-e37e-4bc6-ab1c-f2f648373fdf
title: Open, close and move between full-pane pages
type: feature
status: done
milestone: v0.1
depends_on:
- 355bebe7-8757-4197-8c01-df92624fc0d5
created: 2026-09-26
updated: 2026-09-27
closed_at: 2026-09-27
priority: p0
effort: m
area: chrome
---

## Problem

There are no tabs. One page fills the window, and the others wait out of sight.

## Proposal

The app keeps a list of pages, one visible at a time. `⌘T` opens a new page with the launcher
focused. `⌘W` closes the visible page and shows the next one. `⌥⌘←` and `⌥⌘→` move to the previous
or next page. Closing the last page leaves an empty page with the launcher open, not a closed
window. `⌘1–9` stays unbound until Spaces arrive in v0.2.

## Acceptance criteria

- [x] The page model (order, current page, closing behaviour) lives in `common-core` with unit tests, and the shell only renders it.
- [x] Closing the visible page shows its right-hand neighbour, or the left-hand one if it was last.
- [x] Closing the last page never closes the window.
- [x] Hidden pages keep their state (scroll position and form contents) when shown again.
