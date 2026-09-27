---
id: 1b72d8e0-a662-4684-b008-9f4003fd9924
title: Let Safari's Web Inspector attach to pages
type: feature
status: backlog
milestone: v0.2
created: 2026-09-26
updated: 2026-09-26
priority: p2
effort: s
area: web
---

## Problem

Web developers need an inspector today, before there is an in-app answer.

## Proposal

Set `isInspectable` on every web view when `dev.inspectable = true` (the default), so pages show up
in Safari's Develop menu.

## Acceptance criteria

- [ ] With the key on, a page appears in Safari's Develop menu and can be inspected.
- [ ] With the key off, it does not.
