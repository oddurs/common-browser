---
id: 656e0ddc-fa0b-4433-af72-ab4f8ed2c66b
title: 'Layout tree in core: split, close, focus, swap'
type: feature
status: backlog
milestone: v0.3
depends_on:
- ea887e3a-8896-47b3-8861-f4b7c50ec79a
created: 2026-09-26
updated: 2026-09-26
priority: p0
effort: m
area: core
---

## Problem

Tiling logic is subtle, and all three shells need exactly the same behaviour.

## Proposal

Add a pure layout tree in `common-core` (splits with ratios and pages as leaves), with split, close,
focus by direction, swap by direction and cycle layout. It is persisted with the Space. The shells
only compute frames from it.

## Acceptance criteria

- [ ] Property tests: any sequence of operations leaves a valid tree, with every page in exactly one leaf.
- [ ] Focus by direction picks the geometrically nearest tile, with tests on 2, 3 and 4-tile layouts.
