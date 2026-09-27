---
id: 3a2493bf-3a91-4e30-93dc-7deea4bef0ef
title: Test database migrations from every released schema
type: chore
status: backlog
milestone: v1.0
depends_on:
- ea887e3a-8896-47b3-8861-f4b7c50ec79a
created: 2026-09-26
updated: 2026-09-26
priority: p0
effort: s
area: core
---

## Problem

A migration bug destroys a user's Spaces and history. It is the worst bug this app can have.

## Proposal

Keep a fixture database from every released schema version. A test migrates each one to the
current schema and checks the contents.

## Acceptance criteria

- [ ] Fixtures exist for every schema version shipped since v0.2, and CI migrates each.
- [ ] The app backs up `common.db` before running a migration.
