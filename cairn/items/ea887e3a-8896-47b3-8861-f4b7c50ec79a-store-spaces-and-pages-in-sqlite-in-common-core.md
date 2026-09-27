---
id: ea887e3a-8896-47b3-8861-f4b7c50ec79a
title: Store Spaces and pages in SQLite in common-core
type: feature
status: backlog
milestone: v0.2
depends_on:
- ec66e49d-7ed0-49d7-b6c8-3bf411a58499
created: 2026-09-26
updated: 2026-09-26
priority: p0
effort: m
area: core
---

## Problem

Spaces, pages and history need one durable source of truth that every shell shares.

## Proposal

Store the data in `common.db` under the platform data directory (on macOS, `~/Library/Application
Support/Common`); the shell passes the path in. The tables are `spaces` (id, name, tint, jar,
created, archived_at) and `pages` (id, space_id, url, title, position), with a `schema_version` and
forward-only migrations. Use `rusqlite` with the bundled SQLite. It is the one new dependency,
chosen so every platform has the same SQLite.

## Acceptance criteria

- [ ] CRUD for Spaces and pages is exposed over the bridge and covered by tests against an in-memory database.
- [ ] Opening a database with a newer `schema_version` fails with a clear error instead of corrupting it.
- [ ] Writes are batched; opening 100 pages performs no more than a few transactions.
