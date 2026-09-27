---
id: 4cc437aa-c4a6-463b-8620-1ca0a92411dc
title: JavaScript dialogs and file pickers
type: feature
status: planned
milestone: v0.1
created: 2026-09-26
updated: 2026-09-26
priority: p0
effort: s
area: web
---

## Problem

Without a UI delegate, `alert`, `confirm` and `prompt` hang pages, and file inputs do nothing.

## Proposal

Present JavaScript dialogs as sheets on the window. Present file inputs with `NSOpenPanel`,
respecting `multiple` and directory selection.

## Acceptance criteria

- [ ] `alert`, `confirm` and `prompt` each show a sheet and return the right value to the page.
- [ ] A file input opens a panel, and the chosen files upload.
- [ ] A page that loops `alert` can be stopped: after the second dialog, the sheet offers to block further dialogs from that page.
