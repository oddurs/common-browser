---
id: d865dd06-3b60-4b24-919b-ba95bc7f2168
title: Auto-name and tint Spaces; declare them in common.toml
type: feature
status: backlog
milestone: v0.2
depends_on:
- ea887e3a-8896-47b3-8861-f4b7c50ec79a
- fcb89b44-5b91-4f8e-9c37-d8227399e0c9
created: 2026-09-26
updated: 2026-09-26
priority: p1
effort: s
area: spaces
---

## Problem

Naming things is friction. Spaces should name themselves, and the ones you use every day should be
declared in the file.

## Proposal

A new Space takes the name of its first site's domain and the next unused tint from sage, blue,
sand, clay, plum and slate. `[[space]]` blocks in `common.toml` declare `name`, `tint`, `jar` and
`open` (a list of addresses). Declared Spaces are created on first launch and matched by name
afterwards.

## Acceptance criteria

- [ ] An unknown tint is a config error listing the six tints.
- [ ] Renaming a declared Space in the file renames it in the app on the next reload, and does not create a duplicate.
- [ ] `[[workspace]]` is reported as renamed to `[[space]]`, as in the prototype.
