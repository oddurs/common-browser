---
id: 5e5657e6-273a-4ba3-94af-45ea0606b5dd
title: Publish the app to GitHub Releases on a tag
type: chore
status: doing
milestone: v0.1
depends_on:
- 08d694a4-3d33-4ff0-b526-a48a90ab20ab
created: 2026-09-26
updated: 2026-09-28
priority: p0
effort: s
area: release
---

## Problem

The release workflow creates a release but attaches nothing.

## Proposal

On a `v*` tag, `release.yml` runs `scripts/task check` and `scripts/task package`, then attaches
the zip and its SHA-256 checksum to the release.

## Acceptance criteria

- [ ] Pushing a `v0.1.0-rc.1` tag produces a release with the zip and a `.sha256` file.
- [ ] The downloaded zip's checksum matches, and the app opens after "Open Anyway".

## 2026-09-28

Merged in #26; the packaging half is verified on CI: the PR's release run built the zip on macos-15, its .sha256 checked OK after download, the app is universal and its signature verifies, and the CI-built app launched. Both criteria still need a real tag: pushing v0.1.0-rc.1 publishes a visible prerelease on the public repo, so it waits for the owner's go-ahead.
