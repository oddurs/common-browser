# Open questions

Each question has a recommendation. Where a roadmap item now carries the question, it is named;
the item's answer replaces the row.

| Question | Recommendation | Carried by |
| --- | --- | --- |
| Which app icon direction? | Tiles: it says tiling and Spaces at Dock size, and reads without text. | |
| Name check for "Common" | Search trademarks in software classes and secure a domain. | |
| Should `theme = "auto"` follow the terminal (Ghostty, kitty, Alacritty)? | Yes, as an opt-in value; read their theme files, never run them. | |
| Real page thumbnails in the strip and overview? | Yes, from WebKit snapshots taken on switch, falling back to colour blocks. | `7f72456a` decides snapshots on switch |
| Default for sites asking to send notifications | Deny silently; allow per site from the capsule. | `6d0f3caf` |
| When do idle pages sleep? | After 30 minutes hidden, not counting pages playing media or open in the current Space. | `88324fca` |
| Password managers | Support macOS Passwords AutoFill first; find out whether third-party managers can work in a WebKit app. | `e8cc4389` (spike) |
| Shortcut for Duplicate Space | ⌥⌘N, listed in the File menu. | `9a298aac` |
| Default `window.start` in the app | Full screen, as the principles say. v0.1 ships windowed, and the prototype opens windowed so the desktop shows. | |
| Developer tools | Safari's Web Inspector attaches first; an inspector inside the app is a spike. | `1b72d8e0`, `a8167fdc` (spike) |
| Web extensions | macOS 15.4 added a WebKit extension API for apps; find out what it supports. | `c8e497c4` (spike) |
