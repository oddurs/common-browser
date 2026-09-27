---
id: 2e08777c-7da0-4f69-9413-c68dec13af1e
title: Find in page
type: feature
status: planned
milestone: v0.1
depends_on:
- 355bebe7-8757-4197-8c01-df92624fc0d5
created: 2026-09-26
updated: 2026-09-26
priority: p1
effort: s
area: web
---

## Problem

Find in page is used many times a day.

## Proposal

`⌘F` opens a small find field in the capsule's place. `⌘G` and `⇧⌘G` move between matches, and Esc
closes it. Use `WKWebView`'s find API.

## Acceptance criteria

- [ ] Matches are highlighted and the field shows "3 of 12".
- [ ] "No matches" is shown without an alert sound.
- [ ] Esc closes the find field and leaves the current match selected.
