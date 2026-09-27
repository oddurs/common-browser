---
id: fe8e7d06-5de1-4960-a662-70f91fee1444
title: Reload common.toml live
type: feature
status: backlog
milestone: v0.2
depends_on:
- 266d12d4-7099-406d-9c75-4e60a0fd8151
created: 2026-09-26
updated: 2026-09-26
priority: p1
effort: m
area: config
---

## Problem

Restarting to see a config change breaks the loop of edit and look.

## Proposal

Watch the config file, including editors' atomic-rename saves. On change, reload and apply what
changed without a restart. If there are errors, keep the last good values for the broken keys and
show the banner.

## Acceptance criteria

- [ ] Changing `accent` updates the UI within 200 ms of saving, with no relaunch.
- [ ] Saving with vim, VS Code and TextEdit (atomic rename) all trigger a reload.
- [ ] Fixing the error hides the banner.
