---
id: 24a0bbfa-ef8c-46f5-bea5-255821c8a1dd
title: 'Spike: a Linux shell on GTK 4 and WebKitGTK driven by common-core'
type: spike
status: backlog
milestone: v0.4
depends_on:
- 656e0ddc-fa0b-4433-af72-ab4f8ed2c66b
- ea887e3a-8896-47b3-8861-f4b7c50ec79a
created: 2026-09-26
updated: 2026-09-26
priority: p0
effort: m
area: linux
---

## Question

Can a second shell host the same core without the core changing shape? Build a throwaway GTK 4 +
WebKitGTK 6 window that uses `common-core` for config, pages, Spaces and layout, and list every
place the core API assumes macOS or Swift. Does WebKitGTK's per-context data manager support
per-Space stores the way `WKWebsiteDataStore(forIdentifier:)` does?

## Timebox

Three days. The output is the answer and the list of core changes, not a shell.

## Answer

## Follow-up items

- Core API changes filed in v1.0 under "Freeze the core API".
- The Linux shell's items filed in `later`.
