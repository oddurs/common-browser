---
id: 7ff3fe9f-aea8-48a8-b4f1-86fb680f3175
title: '`common space list` and `common space export`'
type: feature
status: backlog
milestone: v0.2
depends_on:
- ea887e3a-8896-47b3-8861-f4b7c50ec79a
created: 2026-09-26
updated: 2026-09-26
priority: p2
effort: s
area: cli
---

## Problem

The database is the source of truth, and it should still be readable and scriptable.

## Proposal

`common space list` prints one line per Space. `common space export NAME` writes the Space as a
`[[space]]` TOML block that can be pasted into `common.toml`.

## Acceptance criteria

- [ ] An exported block, pasted into the config, recreates an equivalent Space (round-trip test).
- [ ] Both commands work while the app is running (SQLite WAL, read-only).
