---
id: d3d5b112-7500-4386-a83a-066634647e1d
title: Modal input engine in core (keys.mode = "vim")
type: feature
status: backlog
milestone: v0.3
depends_on:
- 53f3307f-07eb-4ac6-b396-3e1b551bd898
created: 2026-09-26
updated: 2026-09-26
priority: p1
effort: m
area: input
---

## Problem

The vim layer's rules (modes, counts, sequences like `gg`) are logic and belong in the core.

## Proposal

A pure state machine in `common-core` takes key events and returns commands. It covers the normal,
insert and hint modes, counts (`5j`) and sequences with a timeout. The shell feeds it only when
focus is not in an editable element.

## Acceptance criteria

- [ ] `keys.mode = "vim"` is accepted by the config and switches the layer on live.
- [ ] Unit tests cover counts, sequences, the timeout and the mode transitions.
- [ ] `i` enters insert mode, Esc leaves it, and the mode is shown in the capsule.
