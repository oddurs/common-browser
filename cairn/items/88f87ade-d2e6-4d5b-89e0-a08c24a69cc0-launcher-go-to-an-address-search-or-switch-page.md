---
id: 88f87ade-d2e6-4d5b-89e0-a08c24a69cc0
title: 'Launcher: go to an address, search, or switch page'
type: feature
status: planned
milestone: v0.1
depends_on:
- 266d12d4-7099-406d-9c75-4e60a0fd8151
- c314de1c-e37e-4bc6-ab1c-f2f648373fdf
created: 2026-09-26
updated: 2026-09-26
priority: p0
effort: m
area: chrome
---

## Problem

The launcher replaces the address bar and the tab strip, so it has to be fast and unambiguous.

## Proposal

`⌘L` opens a centred launcher over the current page, and `⌘T` opens it on a new page. Input with a
scheme, or with a dot and no spaces, is treated as an address. Anything else is a search with
`search.engine`. Below the input, open pages whose title or URL matches are listed first; Return
switches to one. Esc closes the launcher and returns focus to the page.

## Acceptance criteria

- [ ] The classification of input as address or search is in `common-core`, with tests for `localhost:5173`, `example.org`, `what is rust`, `https://x`, `about:blank` and `file:///tmp/a.html`.
- [ ] Typing and Return navigates within one frame of Return.
- [ ] Open pages are matched by title and URL, and the arrow keys and Return select one.
- [ ] Esc restores focus to the element that had it before.
