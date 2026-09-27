# Common Browser

[![CI](https://github.com/oddurs/common-browser/actions/workflows/ci.yml/badge.svg)](https://github.com/oddurs/common-browser/actions/workflows/ci.yml)
[![License: MPL 2.0](https://img.shields.io/badge/license-MPL_2.0-blue.svg)](LICENSE)

An open-source browser you drive from the keyboard. It opens full screen, keeps every setting in
one file (`common.toml`), tiles pages side by side, and groups them into Spaces, each with its own
logins and history. It starts on macOS, where it runs on the system WebKit so scrolling feels
exactly like Safari; Linux and Windows shells come later on the same core.

## What exists today

This is the very start of the project.

- **`crates/common-core`**: the platform-independent core that every shell will share. Today it
  only carries the version.
- **`crates/common-cli`**: the `common` command. Today it answers `common --version`.
- **`apps/macos`**: the macOS app. Today it opens one window with a web view and loads the address
  you pass it.
- **`prototype/`**: a web prototype of the interaction design (Spaces, the launcher, tiling, the
  config file). It is a design reference, not part of the product; see
  [prototype/README.md](prototype/README.md).

## Quickstart

Requirements: macOS 14 or later, Rust (installed with [rustup](https://rustup.rs)), and Swift 6
from Xcode or the Command Line Tools (`xcode-select --install`).

```sh
git clone https://github.com/oddurs/common-browser
cd common-browser
scripts/setup

swift run --package-path apps/macos CommonBrowser https://example.org
cargo run -p common-cli -- --version
```

## Roadmap

[ROADMAP.md](ROADMAP.md) lists every milestone from v0.1 to v1.0 and the work in each. It is
generated from the items in `cairn/items` by [cairn](https://github.com/oddurs/cairn). macOS comes
first; the Rust core is tested on Linux and Windows from v0.1, and those shells follow v1.0.

## Development

All work happens on a branch in its own worktree and lands through a pull request:

```sh
scripts/agent doctor                  # check your setup
scripts/agent start feat/my-idea      # new branch and worktree; cd into the printed path
scripts/agent commit "feat(core): parse common.toml"
scripts/agent pr --body-file pr.md    # runs every check, pushes, opens the pull request
scripts/agent done                    # after merge: removes the worktree and branch
```

`scripts/task check` runs formatting, lint (warnings are errors), tests and the build for both
Rust and Swift. See [CONTRIBUTING.md](CONTRIBUTING.md) for the details.

## License

[Mozilla Public License 2.0](LICENSE). Changes to Common Browser's own files stay open; the code
can still be combined with other work.
