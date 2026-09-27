# Contributing

Thanks for helping. The workflow below is enforced by hooks and branch protection, so following
it is the only way changes land.

## Set up once

```sh
scripts/setup          # git hooks and the pinned Rust toolchain
scripts/agent doctor   # confirms tools, GitHub login and hooks
```

## Make a change

1. Start a branch in its own worktree: `scripts/agent start <type>/<slug>`, then `cd` into the
   path it prints. Types: `feat`, `fix`, `chore`, `docs`, `perf`, `refactor`, `test`.
2. Work there. Never commit in the primary checkout; it stays on `main`.
3. Commit with `scripts/agent commit "<type>(scope): subject"`.
4. Write the description in `pr.md` (git ignores it), starting from
   `.github/PULL_REQUEST_TEMPLATE.md`, then open the pull request with
   `scripts/agent pr --body-file pr.md`. The push runs every check first.
5. Keep up with `main` using `scripts/agent sync`.
6. After the merge, run `scripts/agent done` to remove the worktree and branch.

One unit of work is one worktree, one branch and one pull request. Two people or agents never
share a checkout.

## Commits

[Conventional Commits](https://www.conventionalcommits.org/): `type(scope): subject`, imperative,
72 characters at most, no trailing period. The body explains why; the diff shows what. The
`commit-msg` hook rejects anything else, including AI or assistant attribution.

## Checks

`scripts/task check` runs, in order:

| Step | Rust | Swift |
| --- | --- | --- |
| `fmt:check` | `cargo fmt --check` | `swift format lint --strict` |
| `lint` | `cargo clippy -- -D warnings` | covered by the build |
| `test` | `cargo test` | `swift test` |
| `build` | `cargo build` | `swift build`, warnings as errors |

`test` also runs `scripts/test-workflow`, which tests these hooks and `scripts/agent` itself.

The pre-commit hook runs format and lint; the pre-push hook runs everything and refuses pushes
to `main`. CI runs the same `scripts/task check`.

Xcode is not required. With only the Command Line Tools installed, `scripts/task test` points
`swift test` at the Testing framework the Command Line Tools ship, which SwiftPM does not find on
its own.

## Reviews

`main` requires a pull request with a passing `required` check and resolved conversations.
While the project has a single maintainer, no approving review is required, so the maintainer
is not locked out of their own repository. This changes to one approval once there are more
maintainers.

## Pull request descriptions

State the problem, the approach, and what a reviewer should look at sceptically. Say where the
change is weak rather than leaving it to be found.
