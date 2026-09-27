---
id: 08d694a4-3d33-4ff0-b526-a48a90ab20ab
title: Assemble Common Browser.app from the SwiftPM build
type: feature
status: planned
milestone: v0.1
depends_on:
- ec66e49d-7ed0-49d7-b6c8-3bf411a58499
created: 2026-09-26
updated: 2026-09-26
priority: p0
effort: m
area: macos
---

## Problem

SwiftPM builds an executable, not an app bundle. Without a bundle there is no Dock icon, no
`Info.plist`, no URL handling and nothing to ship.

## Proposal

Add `scripts/task package`. It builds a release for arm64 and x86_64 (Rust with both targets, then
`lipo`), assembles `dist/Common Browser.app` with an `Info.plist` and bundle identifier
`io.github.oddurs.commonbrowser`, ad-hoc signs it with the hardened runtime, and zips it.

## Acceptance criteria

- [ ] `scripts/task package` produces a zip whose app launches from Finder on Apple silicon and Intel.
- [ ] `codesign --verify --deep --strict` passes on the bundle.
- [ ] The build is reproducible from a clean clone with no Xcode project.
