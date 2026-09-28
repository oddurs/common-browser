---
id: 5a5be429-42b6-4767-9222-cdb12a2db911
title: swift test can report success without running every test
type: bug
status: done
milestone: v0.1
created: 2026-09-27
updated: 2026-09-27
closed_at: 2026-09-27
priority: p0
effort: s
area: release
---

## What happens

A test that ends an `NSOpenPanel` makes the test process exit with status 0 before Swift Testing prints its summary. `scripts/task test` then passes after running only part of the suite. A run that stopped the same way, without a summary line, was also seen once while several builds loaded the machine.

## What should happen

`scripts/task test` fails unless the Swift Testing summary line reports that the run passed.

## Reproduction

1. Add a test that shows and ends an `NSOpenPanel`.
2. Run `scripts/task test`: the output stops mid-run, and the exit status is 0.
