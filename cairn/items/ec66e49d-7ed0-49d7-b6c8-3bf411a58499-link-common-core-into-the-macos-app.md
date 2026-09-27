---
id: ec66e49d-7ed0-49d7-b6c8-3bf411a58499
title: Link common-core into the macOS app
type: feature
status: planned
milestone: v0.1
depends_on:
- 5ad0243e-deab-4e83-bacc-abce83512afc
created: 2026-09-26
updated: 2026-09-26
priority: p0
effort: m
area: bridge
---

## Problem

The shell and the core are two separate builds today. Every later feature that keeps its logic in
the core, such as config, Spaces, history and layout, needs Swift to call Rust.

## Proposal

Apply the approach from the bridge spike. `scripts/task build` and `test` build the Rust library
before SwiftPM, so the seam stays the only entry point.

## Acceptance criteria

- [ ] The About panel shows the version read from `common-core`.
- [ ] A Swift test calls into Rust and passes under `scripts/task test`, locally without Xcode and on CI.
- [ ] A clean clone builds with `scripts/setup` followed by `scripts/task build`, with no manual steps.
