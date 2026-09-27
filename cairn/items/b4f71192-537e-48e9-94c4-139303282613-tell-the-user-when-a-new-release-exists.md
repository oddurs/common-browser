---
id: b4f71192-537e-48e9-94c4-139303282613
title: Tell the user when a new release exists
type: feature
status: backlog
milestone: v0.4
depends_on:
- 5e5657e6-273a-4ba3-94af-45ea0606b5dd
created: 2026-09-26
updated: 2026-09-26
priority: p2
effort: s
area: release
---

## Problem

People who installed from a zip never hear about fixes.

## Proposal

Once a day, if `updates.check = true` (the default), ask the GitHub Releases API for the latest
version. If it is newer, show a toast once with the changelog link. Never download or install.

## Acceptance criteria

- [ ] With the key false, the app makes no network request of its own, verified with a proxy.
- [ ] Homebrew installs skip the check, since `brew upgrade` handles updates.
