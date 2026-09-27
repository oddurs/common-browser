---
id: 3d7a1e7a-bcf3-40c2-aecb-a651ad0709e5
title: Freeze the core API and document it for shell authors
type: chore
status: backlog
milestone: v1.0
depends_on:
- 24a0bbfa-ef8c-46f5-bea5-255821c8a1dd
created: 2026-09-26
updated: 2026-09-26
priority: p0
effort: m
area: core
---

## Problem

The core's API is what future shells build on. It must be deliberate before it is promised.

## Proposal

Land the changes the Linux spike asked for, document every public item (`#![deny(missing_docs)]`),
and write `docs/shells.md`: what a shell owns and what the core owns.

## Acceptance criteria

- [ ] `cargo doc` builds with no missing-docs warnings.
- [ ] Every change from the Linux spike's answer has landed or has been explicitly dropped with a reason.
