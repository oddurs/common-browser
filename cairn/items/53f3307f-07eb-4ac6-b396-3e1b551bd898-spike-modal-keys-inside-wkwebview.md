---
id: 53f3307f-07eb-4ac6-b396-3e1b551bd898
title: 'Spike: modal keys inside WKWebView'
type: spike
status: backlog
milestone: v0.3
created: 2026-09-26
updated: 2026-09-26
priority: p0
effort: s
area: input
---

## Question

How do we intercept unmodified keys for the vim layer without breaking pages? Pages handle keys
themselves, and text fields must never be intercepted. Options include an `NSEvent` local monitor
plus a user script that reports focus in editable elements, and responding to `keydown` in an
injected script. How are link-hint overlays drawn: injected DOM, or native views placed over
element rectangles the script reports? And how do cross-origin iframes behave?

## Timebox

One day.

## Answer

## Follow-up items
