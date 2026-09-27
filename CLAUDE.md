# Working in this repository

Common Browser: a keyboard-first, fullscreen browser configured by one file. macOS first on a
Rust core that Linux and Windows shells will share.

## Layout

- `crates/common-core`: platform-independent logic (config, keymap, tiling, Spaces, history).
  No UI toolkit, no web engine, no platform APIs. If it can't be unit-tested without a window, it
  doesn't belong here.
- `crates/common-cli`: the `common` binary. Thin; logic lives in the core.
- `apps/macos`: the Swift package for the macOS shell (AppKit + WKWebView). `CommonApp` is the
  testable library; `CommonBrowser` is the thin executable.
- `prototype/`: a SvelteKit design prototype. Reference only: not in `scripts/task`, not shipped.
  Change it only when asked.

## Workflow (enforced by hooks and branch protection)

1. Never commit on `main`. Start every unit of work with
   `scripts/agent start <type>/<slug>` and work in the printed worktree path.
2. One unit of work → one worktree → one branch → one pull request. Never share a checkout with
   another agent.
3. Commit with `scripts/agent commit "<type>(scope): subject"`: Conventional Commits,
   imperative, ≤ 72 characters, no trailing period; the body says why.
4. Write `pr.md` from `.github/PULL_REQUEST_TEMPLATE.md`: the problem, the approach, and what to
   look at sceptically. `scripts/agent pr --body-file pr.md` runs `scripts/task check`, pushes
   and opens the pull request. It refuses an empty or unfilled description.
5. After merge: `scripts/agent done`.

Never use `--no-verify`, never add `|| true` or `continue-on-error` to get green.

## The toolchain seam

CI, hooks and `scripts/agent` only ever call `scripts/task`:

```
scripts/task fmt | fmt:check | lint | test | build | check
```

New tools or languages are wired into `scripts/task` and nowhere else.

## Attribution

Never name an AI, a model or an assistant anywhere that reaches git or GitHub: no co-author
trailers, no "generated with" lines, no robot emoji, in commits, pull requests, comments, docs
or release notes. The `commit-msg` hook rejects them.

## Code

- Rust: edition 2024, `cargo clippy -D warnings` clean, `unsafe` only in an FFI bridge crate with
  a comment explaining each block. Prefer the standard library; a dependency must earn its place.
- Swift: Swift 6 strict concurrency, UI on the main actor, `swift format` defaults
  (2-space indent, 100 columns). Keep AppKit code in the shell; logic that isn't UI belongs in the
  Rust core.
- Comments explain why, not what. No commented-out code, no TODO stubs.
- A bug fix comes with the test that would have caught it.

## Backlog

Planned work lives in cairn (`cairn` CLI). Work one item per branch and reference it with a
`Refs:` trailer in the commit body.
