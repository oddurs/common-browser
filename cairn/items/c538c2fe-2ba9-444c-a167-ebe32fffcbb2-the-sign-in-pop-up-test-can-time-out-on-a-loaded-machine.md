---
id: c538c2fe-2ba9-444c-a167-ebe32fffcbb2
title: The sign-in pop-up test can time out on a loaded machine
type: bug
status: backlog
milestone: v0.1
created: 2026-09-27
updated: 2026-09-27
priority: p1
effort: s
area: web
---

## What happens

`aPopUpReportsBackToItsOpenerAndClosesItself` failed once with `TimedOut` after 84 seconds, during the release PR's pre-push check on a heavily loaded machine. The same test passed on its own branch, in CI, and in the other full runs that day.

## What should happen

The test passes whenever the flow works, and fails only when the pop-up never reports back or never closes.

## Reproduction

1. Load the machine heavily.
2. Run `scripts/task test` repeatedly until the test times out.
