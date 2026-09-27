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

Apply the answer of `363132d3`. In `release.yml`, in a `release` environment limited to `v*` tags:

- import the Developer ID Application `.p12` into a temporary keychain;
- sign every executable with `codesign --options runtime --timestamp`;
- zip the app with `ditto -c -k --keepParent`;
- run `notarytool submit --wait` with a Team App Store Connect API key;
- run `stapler staple` on the `.app`, then zip it again for the release.

The owner must first enroll in the Apple Developer Program (99 USD a year) and create the
certificate and the key.

## Acceptance criteria

- [ ] A downloaded release opens on first launch with no "Open Anyway" step.
- [ ] `spctl --assess --type exec` accepts the app.
- [ ] The README drops the "Open Anyway" instructions.
