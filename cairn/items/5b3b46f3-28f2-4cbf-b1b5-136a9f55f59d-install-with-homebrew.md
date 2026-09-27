---
id: 5b3b46f3-28f2-4cbf-b1b5-136a9f55f59d
title: Install with Homebrew
type: chore
status: backlog
milestone: v0.2
depends_on:
- 5e5657e6-273a-4ba3-94af-45ea0606b5dd
created: 2026-09-26
updated: 2026-09-26
priority: p1
effort: s
area: release
---

## Problem

A one-command install is part of the promise.

## Proposal

Publish a cask in `oddurs/homebrew-tap`, updated by the release workflow.

## Acceptance criteria

- [ ] `brew install --cask oddurs/tap/common-browser` installs the latest release, and `brew upgrade` picks up the next.
- [ ] The cask also links the `common` CLI.
