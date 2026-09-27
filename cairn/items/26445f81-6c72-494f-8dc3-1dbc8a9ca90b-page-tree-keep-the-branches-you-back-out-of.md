---
id: 26445f81-6c72-494f-8dc3-1dbc8a9ca90b
title: 'Page tree: keep the branches you back out of'
type: feature
status: backlog
milestone: v0.3
depends_on:
- c9483df3-0042-4222-8684-67e00660b530
created: 2026-09-26
updated: 2026-09-26
priority: p1
effort: m
area: history
---

## Problem

Going back and following a different link throws away the forward history. That is the "history
like git" idea from the concept.

## Proposal

Record navigation as a tree per page in the database. A "History of this page" view (`⌘Y`, in the
launcher's style) shows the branches, and choosing a node navigates there. WebKit's own back list
stays linear; the tree is ours.

## Acceptance criteria

- [ ] Back then follow a different link: both branches appear, covered by a core test on the tree.
- [ ] Choosing a node on another branch loads it and makes that branch current.
