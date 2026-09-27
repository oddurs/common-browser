---
id: a5325703-e633-467d-9801-5a94139c7e9e
title: 'Smoke test: load a local page in a web view under swift test'
type: chore
status: planned
milestone: v0.1
created: 2026-09-26
updated: 2026-09-26
priority: p1
effort: m
area: macos
---

## Problem

The shell's web-facing code has no automated test, so regressions show up only by hand.

## Proposal

Add a Swift Testing suite that creates the app's configured `WKWebView`, loads an HTML string,
waits for navigation to finish, and asserts the title and a script result. It becomes the harness
that later web-facing items add cases to.

## Acceptance criteria

- [ ] The test runs under `scripts/task test` locally without Xcode and on CI, headless.
- [ ] It fails if the web view's configuration regresses (for example, if JavaScript is disabled).
