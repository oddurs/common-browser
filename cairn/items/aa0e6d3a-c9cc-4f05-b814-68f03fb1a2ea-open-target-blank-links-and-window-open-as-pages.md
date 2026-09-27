---
id: aa0e6d3a-c9cc-4f05-b814-68f03fb1a2ea
title: Open target=_blank links and window.open as pages
type: feature
status: doing
milestone: v0.1
depends_on:
- c314de1c-e37e-4bc6-ab1c-f2f648373fdf
created: 2026-09-26
updated: 2026-09-27
priority: p0
effort: s
area: web
---

## Problem

Sign-in pop-ups and links that open a new window do nothing in a bare `WKWebView`.

## Proposal

Implement `webView(_:createWebViewWith:for:windowFeatures:)` to create a new page from the given
configuration, so the opener relationship survives, and show it. `window.close()` from script
closes that page.

## Acceptance criteria

- [x] A `target=_blank` link opens a new page and shows it.
- [ ] An OAuth pop-up flow (for example, Sign in with GitHub on a third-party site) completes and returns to the opener.
- [x] `window.close()` from a page opened by script closes it.

## 2026-09-27

Criterion 2 has local evidence, not a real site: aPopUpReportsBackToItsOpenerAndClosesItself opens a pop-up with window.open, the pop-up posts a token to window.opener and calls window.close(), and the opener receives it while the pop-up's page closes and the opener is shown again. A real sign-in (for example, Sign in with GitHub on a third-party site) still needs a person to try it.
