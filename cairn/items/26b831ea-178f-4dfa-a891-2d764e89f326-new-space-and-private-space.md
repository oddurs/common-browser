---
id: 26b831ea-178f-4dfa-a891-2d764e89f326
title: New Space and private Space
type: feature
status: backlog
milestone: v0.2
depends_on:
- 6e0024ef-d6c2-4c49-9556-9393a170726e
- ea887e3a-8896-47b3-8861-f4b7c50ec79a
created: 2026-09-26
updated: 2026-09-26
priority: p0
effort: m
area: spaces
---

## Problem

Spaces are the unit of context: a project, a client, a private errand.

## Proposal

`⌘N` creates a Space with its own data store. `⇧⌘N` creates a private Space: a non-persistent
store, red tint, nothing written to the database and no history.

## Acceptance criteria

- [ ] A login in one Space is not visible in another, verified by the smoke-test harness with a local test server that sets a cookie.
- [ ] Closing a private Space leaves no files behind in its store.
- [ ] A new Space opens with the launcher focused.
