---
id: 1b20aa15-f97c-48e3-beb1-46e899cdcb18
title: Open links from other apps; offer to be the default browser
type: feature
status: backlog
milestone: v0.2
depends_on:
- 08d694a4-3d33-4ff0-b526-a48a90ab20ab
created: 2026-09-26
updated: 2026-09-26
priority: p1
effort: s
area: macos
---

## Problem

A daily browser has to receive links from Mail, Slack and the terminal.

## Proposal

Declare the http and https URL schemes in `Info.plist` and open incoming URLs as a new page in the
current Space. Add a "Make Default Browser" menu item. The app never nags or checks at launch.

## Acceptance criteria

- [ ] `open https://example.org` with Common Browser as default opens a page in the running app.
- [ ] The menu item sets the default through the system's confirmation dialog.
