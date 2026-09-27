---
id: 29681b58-2d3f-4fa5-a6f0-309635bbdbd1
title: 'Security review: entitlements, hardened runtime, threat model'
type: chore
status: backlog
milestone: v1.0
depends_on:
- 74812773-d295-470c-bf49-ef88f4d5c886
created: 2026-09-26
updated: 2026-09-26
priority: p0
effort: m
area: release
---

## Problem

A browser is the most attacked app on the machine.

## Proposal

List every entitlement and justify it. Confirm the hardened runtime and the absence of
`allow-unsigned-executable-memory`. Decide on and document the App Sandbox. Write
`docs/security.md`: the threat model, what WebKit isolates, and what private Spaces protect against
and what they do not.

## Acceptance criteria

- [ ] `docs/security.md` exists and is linked from `SECURITY.md`.
- [ ] Every entitlement in the signed app appears in the doc with a reason.
