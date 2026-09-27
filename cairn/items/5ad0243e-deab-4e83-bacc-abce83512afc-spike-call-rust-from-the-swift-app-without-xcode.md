---
id: 5ad0243e-deab-4e83-bacc-abce83512afc
title: 'Spike: call Rust from the Swift app without Xcode'
type: spike
status: done
milestone: v0.1
created: 2026-09-26
updated: 2026-09-27
closed_at: 2026-09-27
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

**UniFFI 0.32**, through a thin `crates/common-ffi` crate (a `staticlib`) that wraps
`common-core`, and a `crates/uniffi-bindgen` binary that generates the Swift side.

- **Why not a hand-written C ABI with cbindgen:** every type that crosses the boundary (config
  errors, the page model, the layout tree) would need hand-written marshalling and `unsafe` on
  both sides. UniFFI generates records, enums, errors and callbacks, checked at build time.
- **Why not swift-bridge:** it is still 0.1.x. UniFFI runs in production at Mozilla (Firefox for
  iOS) and Matrix, and also targets Kotlin and Python.
- **The other shells need no bridge.** A Linux shell on gtk4-rs + webkit6 and a Windows shell on
  windows-rs + WebView2 can be written in Rust and call `common-core` directly. The bridge is
  macOS plumbing, kept out of the core.
- **No Xcode needed.** `xcodebuild -create-xcframework` is not used. `scripts/task` builds the
  static library and runs library-mode generation (`--library libcommon_ffi.a`) into
  `apps/macos/Generated/` (gitignored), copying only changed files so SwiftPM does not rebuild.
  `Package.swift` has a `systemLibrary` target for the C header and module map, and a Swift target
  for the bindings, linked with `-L Generated/lib -lcommon_ffi` through `unsafeFlags`, which a root
  package may use.
- **Measured:** `common-ffi` adds 58 crates to the build. `uniffi-bindgen` takes 2.5 minutes cold,
  cached afterwards. The debug static library is 22 MB. The generated Swift compiles under Swift 6
  with warnings as errors.
- **Costs:** SwiftPM alone cannot build the app; `scripts/task build` must run first (README and
  CLAUDE.md say so). Universal release builds need the Rust library for both architectures, joined
  with `lipo`. The package cannot be used as a dependency of another package, because of
  `unsafeFlags`; that is not a goal.

## Follow-up items

- `ec66e49d` "Link common-core into the macOS app" implements this answer.
- `08d694a4` "Assemble Common Browser.app" must build the release library for arm64 and x86_64
  and `lipo` them before `swift build -c release`.

- "Link common-core into the macOS app" gets the chosen approach written into its proposal.
