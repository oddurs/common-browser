---
id: 63a3ee07-4841-4948-b53a-516b5bcaaab0
title: Full-size window, native full screen, remembered frame
type: feature
status: planned
milestone: v0.1
created: 2026-09-26
updated: 2026-09-26
priority: p1
effort: s
area: macos
---

## Problem

The page should own the whole window. The traffic lights stay, but there is no toolbar and no title
bar strip.

## Proposal

Keep the window's `fullSizeContentView` and transparent title bar, support native full screen
(`⌃⌘F`), and save and restore the window frame.

## Acceptance criteria

- [ ] The page content starts at the top edge of the window, under the traffic lights.
- [ ] `⌃⌘F` enters and leaves native full screen.
- [ ] Relaunching restores the previous window frame, and a frame that no longer fits a screen is moved onto one.
