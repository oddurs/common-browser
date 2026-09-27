---
id: 5321df17-218a-41ea-8aaf-de837730fe3f
title: Performance budgets and scripts/bench
type: feature
status: backlog
milestone: v0.4
depends_on:
- 08d694a4-3d33-4ff0-b526-a48a90ab20ab
created: 2026-09-26
updated: 2026-09-26
priority: p0
effort: m
area: perf
---

## Problem

"So damn fast" needs numbers, or it erodes one reasonable change at a time.

## Proposal

`docs/performance.md` sets budgets on an M1 MacBook Air: cold launch to an interactive window
≤ 300 ms, launcher open ≤ 1 frame, page switch ≤ 1 frame, and idle memory of the browser process
≤ 80 MB. `scripts/bench` measures them. CI runs it on a schedule and uploads the results, without
gating, because shared runners are too noisy.

## Acceptance criteria

- [ ] `scripts/bench` prints each budget with its measurement and a pass or fail.
- [ ] Budgets are met at the end of the milestone, or the doc records why a budget changed.
