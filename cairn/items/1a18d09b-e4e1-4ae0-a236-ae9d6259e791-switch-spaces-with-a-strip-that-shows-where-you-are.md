---
id: 1a18d09b-e4e1-4ae0-a236-ae9d6259e791
title: Switch Spaces, with a strip that shows where you are
type: feature
status: backlog
milestone: v0.2
depends_on:
- 26b831ea-178f-4dfa-a891-2d764e89f326
created: 2026-09-26
updated: 2026-09-26
priority: p0
effort: s
area: chrome
---

## Problem

Without a visible cue, it is easy to lose track of which Space you are in.

## Proposal

`⌘1–9` goes to a Space, and `⇧⌘[` and `⇧⌘]` step through them. On every switch, a strip of Space
tiles fades in along the top, marks the current one, and fades out after 900 ms. The capsule shows
the Space's tint dot and name. Transitions use the 300 ms space motion token.

## Acceptance criteria

- [ ] Switching Spaces shows the strip with the current Space marked.
- [ ] `⇧⌘1–9` sends the current page to that Space.
- [ ] With Reduce Motion on, switching is instant, with no slide.
