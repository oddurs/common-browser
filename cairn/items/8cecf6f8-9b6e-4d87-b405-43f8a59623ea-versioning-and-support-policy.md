---
id: 8cecf6f8-9b6e-4d87-b405-43f8a59623ea
title: Versioning and support policy
type: docs
status: backlog
milestone: v1.0
created: 2026-09-26
updated: 2026-09-26
priority: p1
effort: s
area: docs
---

## Problem

"Stable" means nothing without saying what is covered.

## Proposal

State what semver covers: the config file, the CLI's commands and exit codes, and the database
(migrated, never broken). The core's Rust API is covered only for shell authors inside this
repository. Update the supported versions in `SECURITY.md`.

## Acceptance criteria

- [ ] `docs/versioning.md` exists and is linked from the README and `SECURITY.md`.
