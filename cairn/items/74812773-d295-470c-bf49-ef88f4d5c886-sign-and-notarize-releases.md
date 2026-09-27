---
id: 74812773-d295-470c-bf49-ef88f4d5c886
title: Sign and notarize releases
type: feature
status: backlog
milestone: v0.2
depends_on:
- 363132d3-d4a8-431e-b2cc-0a54c9d9c754
- 5e5657e6-273a-4ba3-94af-45ea0606b5dd
created: 2026-09-26
updated: 2026-09-26
priority: p1
effort: m
area: release
---

## Problem

Gatekeeper warnings are a poor first impression and teach people to click through them.

## Proposal

Apply the spike's answer: sign with the Developer ID certificate from CI secrets, notarize with
`notarytool`, and staple the ticket.

## Acceptance criteria

- [ ] A downloaded release opens on first launch with no "Open Anyway" step.
- [ ] `spctl --assess --type exec` accepts the app.
- [ ] The README drops the "Open Anyway" instructions.
