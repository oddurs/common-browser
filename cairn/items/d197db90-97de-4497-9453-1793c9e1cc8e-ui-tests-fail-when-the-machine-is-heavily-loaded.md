---
id: d197db90-97de-4497-9453-1793c9e1cc8e
title: UI tests fail when the machine is heavily loaded
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

At load averages of 166 to 223, four dialog tests and one notice test failed, each on a 10-second wait for a sheet to appear or a notice to go. The pre-push hook runs the whole suite, so these failures blocked unrelated pull requests.

## What should happen

The UI tests pass on a loaded machine and still fail when a sheet or notice never appears.

## Reproduction

1. Load the machine heavily (several parallel builds).
2. Run `scripts/task test`: `DialogsTests` fail with `NoSheet`, and `aNoticeGoesAwayUnlessANewerOneReplacedIt` fails.

## 2026-09-27

Fixed in #19: dialog tests run in a serialized suite and every UI wait shares a 60-second uiTimeout. After the fix the suite passed three runs in a row at load averages 65 to 136 (87, 12 and 30 s). Filed after the fact because cairn could not write while that PR went in.
