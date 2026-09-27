---
id: c6e095e3-bba1-4372-84f4-9f995d577230
title: Test common-core on Linux and Windows in CI
type: chore
status: doing
milestone: v0.1
created: 2026-09-26
updated: 2026-09-27
priority: p1
effort: s
area: release
---

## Problem

The core is meant to serve three shells. If it is only ever built on macOS, it will quietly grow
macOS assumptions such as paths, line endings and case-insensitive file names.

## Proposal

Add `scripts/task check:core` (fmt:check, clippy and tests for the Rust workspace only). Add CI
jobs on `ubuntu-latest` and `windows-latest` that run it, and make `required` depend on them.

## Acceptance criteria

- [ ] CI runs the Rust workspace tests on Linux, Windows and macOS, and `required` fails if any of them fails.
- [ ] The CI YAML calls only `scripts/task`, with no raw cargo commands.
