---
id: 5e2d8493-f3ae-40e5-a860-94f6e9ed1657
title: Add `common config check`
type: feature
status: planned
milestone: v0.1
depends_on:
- fcb89b44-5b91-4f8e-9c37-d8227399e0c9
created: 2026-09-26
updated: 2026-09-26
priority: p1
effort: s
area: cli
---

## Problem

A config mistake should be findable without opening the app, and from an editor or a script.

## Proposal

`common config check [--path FILE]` loads the config through `common_core::config` and prints each
error as `file:line:col: message`, the format editors already understand.

## Acceptance criteria

- [ ] A valid file prints nothing and exits 0.
- [ ] An invalid file prints one line per error and exits 1, covered by a test using a temporary file.
- [ ] A missing `--path` file exits 1 and names the path.
- [ ] `common --help` lists the command.
