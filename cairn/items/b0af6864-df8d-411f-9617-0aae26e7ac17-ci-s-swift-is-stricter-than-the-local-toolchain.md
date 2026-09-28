---
id: b0af6864-df8d-411f-9617-0aae26e7ac17
title: CI's Swift is stricter than the local toolchain
type: chore
status: backlog
milestone: v0.1
created: 2026-09-28
updated: 2026-09-28
priority: p1
effort: s
area: release
---

## Problem

`scripts/task check` passed locally (Command Line Tools, Swift 6.3), then CI's macOS job (Xcode on `macos-15`) rejected the same code under Swift 6's concurrency checking: "non-sendable result type 'T?' cannot be sent from nonisolated context" in #22. A green local check does not promise a green CI.

## Proposal

Find out which Xcode and Swift the runner uses, and either select a matching Xcode in `ci.yml` (`sudo xcode-select -s …`) or document the gap in CONTRIBUTING with the concurrency patterns that differ. Prefer matching the toolchain: the same compiler in both places is what makes the pre-push check worth waiting for.

## Acceptance criteria

- [ ] The CI log prints the Swift version it builds with, and it matches the version the README asks contributors to use, or CONTRIBUTING states the difference.
