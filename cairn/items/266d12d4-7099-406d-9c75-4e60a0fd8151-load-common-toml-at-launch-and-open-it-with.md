---
id: 266d12d4-7099-406d-9c75-4e60a0fd8151
title: Load common.toml at launch and open it with ⌘,
type: feature
status: doing
milestone: v0.1
depends_on:
- 63a3ee07-4841-4948-b53a-516b5bcaaab0
- ec66e49d-7ed0-49d7-b6c8-3bf411a58499
- fcb89b44-5b91-4f8e-9c37-d8227399e0c9
created: 2026-09-26
updated: 2026-09-27
priority: p0
effort: s
area: config
---

## Problem

The app has to honour the file, and the file has to be one keystroke away because it is the
settings.

## Proposal

At launch, load the config through the core and apply `window.start`, `home` and `search.engine`.
If there are errors, start with the defaults for the broken keys and show a banner with the first
error and the count. `⌘,` opens the file in the default editor, first creating it from a commented
template if it does not exist.

## Acceptance criteria

- [x] `window.start = "fullscreen"` launches in full screen.
- [x] A broken key shows a banner naming the line; the other keys still apply.
- [ ] `⌘,` on a machine with no config creates the file with every v0.1 key commented and opens it.

## 2026-09-27

Criterion 3 is covered up to the hand-off: a test proves ⌘, (openConfigFile) writes the commented template under XDG_CONFIG_HOME and passes that path to the opener. The last step, NSWorkspace opening it in the default editor (TextEdit if nothing claims .toml), needs a person to press ⌘, once on a machine without a config.
