---
id: fd50f7c7-52d2-4a0f-a14d-8ea68fa96cc2
title: Install guide and config reference for v0.1
type: docs
status: planned
milestone: v0.1
depends_on:
- 5e5657e6-273a-4ba3-94af-45ea0606b5dd
- fcb89b44-5b91-4f8e-9c37-d8227399e0c9
created: 2026-09-26
updated: 2026-09-26
priority: p0
effort: s
area: docs
---

## Problem

A stranger has to be able to install the app, get past Gatekeeper, and know every setting.

## Proposal

The README's Install section covers the download, "Open Anyway" and `common` on the PATH. A new
`docs/config.md` lists every key with its type, default and an example.

## Acceptance criteria

- [ ] A test fails if `common_core::config` has a key that `docs/config.md` does not mention.
- [ ] Someone other than the author follows the README on a clean Mac and reports no missing step.
