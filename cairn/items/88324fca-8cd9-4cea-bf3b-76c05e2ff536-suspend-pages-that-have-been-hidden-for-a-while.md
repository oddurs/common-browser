---
id: 88324fca-8cd9-4cea-bf3b-76c05e2ff536
title: Suspend pages that have been hidden for a while
type: feature
status: backlog
milestone: v0.4
depends_on:
- 2d3009ea-eb3f-41b3-b4fe-3b72a98afb0b
created: 2026-09-26
updated: 2026-09-26
priority: p1
effort: m
area: perf
---

## Problem

Fifty pages in memory is the most common way browsers get slow.

## Proposal

Pages hidden for `pages.suspend_after` (default 30 minutes) are released. The shell keeps a
snapshot image and the URL, and reloads the page when it is shown. Pages playing media or with
unsent form input are never suspended.

## Acceptance criteria

- [ ] Memory with 50 pages open, 49 hidden for longer than the timeout, is within 20% of memory with 1 page.
- [ ] A page with a half-filled form is not suspended.
