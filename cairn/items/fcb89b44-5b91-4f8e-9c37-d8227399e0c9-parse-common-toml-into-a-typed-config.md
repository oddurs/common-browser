---
id: fcb89b44-5b91-4f8e-9c37-d8227399e0c9
title: Parse common.toml into a typed config
type: feature
status: planned
milestone: v0.1
created: 2026-09-26
updated: 2026-09-26
priority: p0
effort: m
area: config
---

## Problem

The config file is the only settings surface, so a mistake in it has to be as easy to fix as a
compiler error. Today nothing reads it.

## Proposal

Add `common_core::config`: load `$XDG_CONFIG_HOME/common/common.toml`, falling back to
`~/.config/common/common.toml`, into a typed `Config` with defaults for every key. The v0.1 keys:
`window.start` (`windowed` | `fullscreen`), `theme`, `theme_light`, `accent`, `search.engine` (a
URL template containing `%s`), `home`, and `keys.mode` (`standard` only; `vim` is rejected with
"arrives in v0.3").

Errors carry a line, a column, the key path and, for unknown keys, the nearest known key. The
prototype's `src/lib/server/config.js` has the same rules to port. `serde` and `toml` are the only
new dependencies.

## Acceptance criteria

- [ ] A missing file gives the defaults, not an error.
- [ ] An unknown key reports its line and column and suggests the nearest key (`thme` → "did you mean `theme`?"), covered by a test.
- [ ] A value of the wrong type names the expected type and the line, covered by a test.
- [ ] Several errors in one file are all reported, not just the first.
- [ ] An invalid `search.engine` without `%s` is an error that says so.
