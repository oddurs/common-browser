---
id: ed7ae6dd-870d-4296-a3a6-7d043f45aed7
title: VoiceOver and keyboard reachability for the browser's own UI
type: feature
status: backlog
milestone: v0.4
depends_on:
- 78c0e713-5555-40b7-8251-3930954469c0
- 7f72456a-ae7a-4223-b8f1-b33e539b0270
created: 2026-09-26
updated: 2026-09-26
priority: p0
effort: m
area: a11y
---

## Problem

A browser with no visible chrome can easily be invisible to assistive technology too.

## Proposal

Audit and fix every native control: the launcher, capsule, strip, overview, find, toasts, banners
and prompts. Each needs an accessibility role, label and value, and a keyboard path.

## Acceptance criteria

- [ ] A VoiceOver user can open a page, switch Space, find a history entry and close a page without sight, done as a recorded test script.
- [ ] Accessibility Inspector reports no missing labels on the browser's UI.
