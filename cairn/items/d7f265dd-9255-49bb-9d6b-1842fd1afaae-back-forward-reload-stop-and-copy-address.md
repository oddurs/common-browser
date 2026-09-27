---
id: d7f265dd-9255-49bb-9d6b-1842fd1afaae
title: Back, forward, reload, stop and copy address
type: feature
status: planned
milestone: v0.1
depends_on:
- 355bebe7-8757-4197-8c01-df92624fc0d5
created: 2026-09-26
updated: 2026-09-26
priority: p0
effort: s
area: web
---

## Problem

The basic navigation commands need shortcuts and menu items.

## Proposal

Register `⌘[` back, `⌘]` forward, `⌘R` reload, `⌘.` stop and `⇧⌘C` copy address with the command
registry, backed by `WKWebView`. Two-finger swipe back and forward uses WebKit's own gesture, so it
feels exactly like Safari.

## Acceptance criteria

- [ ] Each command is disabled in the menu when it cannot act (for example, back with no history).
- [ ] Swipe navigation is enabled (`allowsBackForwardNavigationGestures`).
- [ ] `⇧⌘C` puts the current URL on the pasteboard and confirms with a brief toast.
