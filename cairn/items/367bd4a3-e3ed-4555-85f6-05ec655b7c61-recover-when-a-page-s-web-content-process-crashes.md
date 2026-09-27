---
id: 367bd4a3-e3ed-4555-85f6-05ec655b7c61
title: Recover when a page's web content process crashes
type: feature
status: backlog
milestone: v0.2
created: 2026-09-26
updated: 2026-09-26
priority: p0
effort: s
area: web
---

## Problem

When a web content process dies, the page goes blank with no explanation.

## Proposal

Handle `webViewWebContentProcessDidTerminate`: a visible page reloads once automatically. If it
crashes again within a minute, show a notice with a Reload button instead of looping.

## Acceptance criteria

- [ ] Killing the web content process of the visible page reloads it.
- [ ] A second crash within a minute shows the notice and does not reload.
