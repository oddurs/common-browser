# Changelog

All notable changes to this project are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the project uses
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- A menu bar that lists every command with its shortcut, including standard editing (copy, paste,
  undo) inside pages.
- `common config check [--path FILE]` reports each error in `common.toml` as
  `FILE:LINE:COL: MESSAGE` and exits 1 if there are any.
