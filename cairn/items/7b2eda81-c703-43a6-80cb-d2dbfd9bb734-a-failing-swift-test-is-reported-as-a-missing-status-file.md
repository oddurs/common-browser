---
id: 7b2eda81-c703-43a6-80cb-d2dbfd9bb734
title: A failing swift test is reported as a missing status file
type: bug
status: done
milestone: v0.1
created: 2026-09-27
updated: 2026-09-27
closed_at: 2026-09-27
priority: p1
effort: s
area: release
---

## What happens

When `swift test` fails, `scripts/task test` prints `cat: …status: No such file or directory` after the test output. `set -e` ends the piped group as soon as `swift test` fails, before its exit status is written to the file `scripts/task` reads. The run still fails, but the last message points at the wrong thing.

## What should happen

A failing `swift test` fails `scripts/task test` with swift's own output and status, and nothing else.

## Reproduction

1. Make any Swift test fail.
2. Run `scripts/task test`: the output ends with `cat: /var/folders/…/tmp.XXXX.status: No such file or directory`.
