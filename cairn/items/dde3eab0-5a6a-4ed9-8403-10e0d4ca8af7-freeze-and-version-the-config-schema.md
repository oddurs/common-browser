---
id: dde3eab0-5a6a-4ed9-8403-10e0d4ca8af7
title: Freeze and version the config schema
type: feature
status: backlog
milestone: v1.0
depends_on:
- d865dd06-3b60-4b24-919b-ba95bc7f2168
- fe8e7d06-5de1-4960-a662-70f91fee1444
created: 2026-09-26
updated: 2026-09-26
priority: p0
effort: m
area: config
---

## Problem

After 1.0, a config file that worked must keep working.

## Proposal

Add a top-level `version = 1` key; a file without one is read as version 1. Renamed keys keep
working with a warning that names the new key. Unknown keys in a newer version fail with "this
file needs Common Browser 1.x or later". Document the compatibility rules.

## Acceptance criteria

- [ ] A fixture file containing every 1.0 key is checked into the tests and must keep parsing.
- [ ] `docs/config.md` states the compatibility promise.
