---
id: 0863f4a1-26cd-4682-8b81-787c54810751
title: 'Release candidate: two weeks as the only browser'
type: chore
status: backlog
milestone: v1.0
depends_on:
- 29681b58-2d3f-4fa5-a6f0-309635bbdbd1
- 5321df17-218a-41ea-8aaf-de837730fe3f
- ed7ae6dd-870d-4296-a3a6-7d043f45aed7
created: 2026-09-26
updated: 2026-09-26
priority: p0
effort: m
area: release
---

## Problem

The only honest test of a daily browser is using it daily.

## Proposal

Tag `v1.0.0-rc.1`. The maintainer uses it as their only browser for two weeks, filing every rough
edge. p0 bugs block 1.0, and everything else is triaged into 1.x or `later`.

## Acceptance criteria

- [ ] Two weeks elapsed with no open p0 bugs at the end.
- [ ] `CHANGELOG.md` has a complete 1.0.0 entry.
