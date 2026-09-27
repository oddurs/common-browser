---
id: ef5185b9-73b8-4b50-b28b-74be2c3a7282
title: Archive a Space when its last page closes
type: feature
status: backlog
milestone: v0.2
depends_on:
- 7f72456a-ae7a-4223-b8f1-b33e539b0270
- ea887e3a-8896-47b3-8861-f4b7c50ec79a
created: 2026-09-26
updated: 2026-09-26
priority: p1
effort: m
area: spaces
---

## Problem

Closing a Space's last page should not destroy the Space. It should be one step from coming back.

## Proposal

Closing the last page archives the Space: it records the open pages and sets `archived_at`. The
overview lists archived Spaces under "Recently closed", and choosing one restores it with its pages.
Archives older than `spaces.keep_archived` (default 30 days) are pruned at launch.

## Acceptance criteria

- [ ] Archive then restore returns the same pages in the same order, covered by a core test.
- [ ] Moving the last page to another Space removes the emptied Space without archiving it.
- [ ] Pruning never deletes a jar that another Space still uses.
