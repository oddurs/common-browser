---
id: 1778290b-d0fa-4561-b095-36bd85f01755
title: 'Capsule: title, position and loading state'
type: feature
status: planned
milestone: v0.1
depends_on:
- c314de1c-e37e-4bc6-ab1c-f2f648373fdf
created: 2026-09-26
updated: 2026-09-26
priority: p1
effort: s
area: chrome
---

## Problem

With no title bar and no tabs, nothing tells you which page you are on or whether it is loading.

## Proposal

A small glass capsule at the top centre shows the page title and "N of M". It fades in on page
changes, navigation and hover near the top edge, and fades out after 1.2 s idle. A thin progress
line runs along its bottom while loading. Motion uses the prototype's tokens: fade 140 ms, and the
spring `cubic-bezier(0.32, 0.72, 0, 1)`.

## Acceptance criteria

- [ ] Switching pages shows the new title and position, then fades.
- [ ] Loading shows progress, and the line finishes before the capsule fades.
- [ ] With Reduce Motion on, the capsule appears and disappears without animation.
