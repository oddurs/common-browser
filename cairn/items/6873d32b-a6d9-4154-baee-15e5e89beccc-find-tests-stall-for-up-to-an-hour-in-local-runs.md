---
id: 6873d32b-a6d9-4154-baee-15e5e89beccc
title: Find tests stall for up to an hour in local runs
type: bug
status: backlog
milestone: v0.1
created: 2026-09-28
updated: 2026-09-28
priority: p1
effort: m
area: web
---

## What happens

On this machine, with heavy load, the full suite twice took far longer than usual while still passing: 3,619 seconds, with four find tests at about 3,615 seconds each, and 2,169 seconds, with `theBarShowsTheCountAndSteps` alone at 2,169. Normally the suite takes 12–120 seconds. The find tests wait on `WKWebView.find` and `callAsyncJavaScript` through `FindState.settle()`, which has no timeout. CI has not shown it.

## What should happen

A find test either finishes in seconds or fails within the shared UI timeout.

## Reproduction

1. Run `scripts/task test` repeatedly on a heavily loaded Mac.
2. Some runs report a find test passing after thousands of seconds.

Suspected cause, unverified: WebKit throttles or suspends the content processes of pages in windows it considers invisible. The test runner is a background process whose windows are never shown.
