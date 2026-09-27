---
id: 3c0c5514-8b42-4585-a471-98bce2d3ab74
title: Block ads and trackers with filter lists
type: feature
status: backlog
milestone: v0.4
depends_on:
- 85661946-edfc-4ad8-85b1-b713701f1428
created: 2026-09-26
updated: 2026-09-26
priority: p1
effort: m
area: privacy
---

## Problem

Users expect a fast browser to block ads and trackers.

## Proposal

Apply the spike's approach. `privacy.block = ["easylist", "easyprivacy"]` in the config, lists
updated weekly in the background, and a per-site toggle command.

## Acceptance criteria

- [ ] Page-load time on a fixed test set does not regress by more than 5% compared with blocking off.
- [ ] The per-site toggle persists per Space.
