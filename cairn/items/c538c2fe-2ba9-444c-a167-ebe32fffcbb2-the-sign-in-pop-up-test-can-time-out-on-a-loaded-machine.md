---
id: c538c2fe-2ba9-444c-a167-ebe32fffcbb2
title: The sign-in pop-up test can time out on a loaded machine
type: bug
status: done
milestone: v0.1
created: 2026-09-27
updated: 2026-09-28
closed_at: 2026-09-28
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

## 2026-09-28

Changed in the same PR: the pages are now served over HTTP on 127.0.0.1 (the downloads tests' TestServer) instead of file://, removing the dependence on which WebKit content process a pop-up lands in and whether it was granted read access to the files' directory. Evidence is circumstantial: the timeout never reproduced in isolation (5 of 5 passed before and after), and the served version then passed 5 of 5 and a full check. Reopen if it recurs.
