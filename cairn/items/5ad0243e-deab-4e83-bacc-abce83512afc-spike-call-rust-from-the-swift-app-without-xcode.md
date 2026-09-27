---
id: 5ad0243e-deab-4e83-bacc-abce83512afc
title: 'Spike: call Rust from the Swift app without Xcode'
type: spike
status: planned
milestone: v0.1
created: 2026-09-26
updated: 2026-09-26
priority: p0
effort: m
area: bridge
---

## Question

How does the macOS app link `common-core` and call it from Swift? The build has to work with only
the Command Line Tools locally and with Xcode on CI, and the choice must leave the Linux (C/GTK)
and Windows shells possible.

Candidates: UniFFI (generated Swift bindings), swift-bridge, and a hand-written C ABI with a
cbindgen header and a SwiftPM module map. Packaging questions for each: `xcodebuild
-create-xcframework` is not available without Xcode, so find out whether a static library plus a
module map linked through SwiftPM works. Also decide who builds the Rust library first: a SwiftPM
plugin or `scripts/task`.

## Timebox

One day. Build a throwaway branch that calls `common_core::VERSION` from `swift test`.

## Answer

## Follow-up items

- "Link common-core into the macOS app" gets the chosen approach written into its proposal.
