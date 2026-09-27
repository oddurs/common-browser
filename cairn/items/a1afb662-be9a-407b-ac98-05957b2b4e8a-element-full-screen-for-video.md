---
id: a1afb662-be9a-407b-ac98-05957b2b4e8a
title: Element full screen for video
type: feature
status: doing
milestone: v0.1
created: 2026-09-26
updated: 2026-09-27
priority: p1
effort: s
area: web
---

## Problem

Video players' full-screen buttons fail unless element full screen is enabled.

## Proposal

Enable `isElementFullscreenEnabled` on the web view preferences.

## Acceptance criteria

- [ ] The full-screen button on a YouTube and a Vimeo video fills the screen, and Esc returns.
- [ ] Leaving element full screen restores the page's previous layout and scroll position.
