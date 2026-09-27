---
id: 363132d3-d4a8-431e-b2cc-0a54c9d9c754
title: 'Spike: Developer ID signing and notarization in CI'
type: spike
status: planned
milestone: v0.1
created: 2026-09-26
updated: 2026-09-26
priority: p1
effort: s
area: release
---

## Question

What does it take to ship a signed, notarized app from GitHub Actions? This covers the Apple
Developer Program cost and account, storing the certificate and a notarytool API key as secrets,
and whether `codesign` and `xcrun notarytool` work with the runner's Xcode. What exactly does an
unsigned or ad-hoc app cost a user on current macOS?

## Timebox

Half a day. No certificate purchase until the owner decides.

## Answer

## Follow-up items

- "Sign and notarize releases" in v0.2, if the answer is yes.
