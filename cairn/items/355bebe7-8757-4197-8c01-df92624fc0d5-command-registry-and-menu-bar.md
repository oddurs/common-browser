---
id: 355bebe7-8757-4197-8c01-df92624fc0d5
title: Command registry and menu bar
type: feature
status: done
milestone: v0.1
created: 2026-09-26
updated: 2026-09-27
closed_at: 2026-09-27
priority: p0
effort: m
area: input
---

## Problem

Shortcuts sprawl unless one list owns them. The menu bar has to show every command, so the list
and the menus cannot be allowed to drift apart.

## Proposal

Every action is a named command with an id, a title, a menu and a default shortcut, defined in one
table. The menu bar is built from that table. Later features register commands; they never bind
keys directly.

## Acceptance criteria

- [x] Adding one entry to the table adds the menu item and its shortcut.
- [x] A test fails if two commands share a shortcut.
- [x] The standard shortcuts that exist in v0.1 (`⌘T`, `⌘W`, `⌘L`, `⌘[`, `⌘]`, `⌘R`, `⇧⌘C`, `⌘F`, `⌘,`, `⌃⌘F`) appear in the menus with their glyphs.
