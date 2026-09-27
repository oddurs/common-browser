# Config

All settings live in `~/.config/common/common.toml`, and `$XDG_CONFIG_HOME` is respected. Defaults
are built in, so an empty file works and the file only records what you changed. ⌘, opens it in
your editor, first writing one that lists every key, commented out at its default.

## Reload rules

- Saving the file applies it within a moment; a notification lists the keys that changed.
- Each key is checked on its own. A bad value keeps its previous value (its default at launch) and
  is reported with its line and a suggested fix, such as "unknown key `gap` in [tiling] (did you
  mean `gaps`?)".
- A syntax error keeps the whole previous config and reports the line.
- `common config check` runs the same checks from a terminal and exits non-zero on errors.

v0.1 reads the file at launch; live reload arrives in v0.2 (item `fe8e7d06`).

## Keys

"v0.1" means the app reads the key today; anything else is planned, with the milestone that brings
it where one is set.

| Key | Values | Default | What it does | When |
| --- | --- | --- | --- | --- |
| `home` | an address with a scheme | `"about:blank"` | The page a new window or page opens | v0.1 |
| `theme` | a theme name | `"graphite"` | Theme while macOS is in dark mode | v0.1 |
| `theme_light` | a theme name | `"paper"` | Theme while macOS is in light mode | v0.1 |
| `accent` | `#rrggbb` | `"#d9895b"` | The accent colour | v0.1 |
| `window.start` | `windowed`, `fullscreen` | `"windowed"` | How the window opens | v0.1 |
| `search.engine` | URL with `%s` | DuckDuckGo | Where launcher searches go | v0.1 |
| `keys.mode` | `standard`, `vim` | `"standard"` | Adds the vim layer when set to vim | v0.1 (`vim` in v0.3) |
| `font.ui` | `"system"` or a family | `"system"` | Font for everything you read | |
| `font.mono` | a family | `"SF Mono"` | Font for key hints, code and config | |
| `font.size` | 10–24 | `13` | Chrome text size in points | |
| `window.chrome` | `capsule`, `bar`, `none` | `"capsule"` | Floating capsule, a permanent bar, or nothing but the launcher | |
| `window.hide_after` | a duration like `"0.8s"` | `"0.8s"` | How long the capsule lingers after the pointer leaves | |
| `window.corner` | 0–32 | `14` | Corner radius of tiled pages | v0.3 |
| `tiling.layout` | `master`, `columns`, `monocle` | `"master"` | Default layout for new Spaces | v0.3 |
| `tiling.ratio` | 0.3–0.8 | `0.58` | Width of the main page in master layout | v0.3 |
| `tiling.gaps` | 0–48 | `10` | Space between tiled pages, in points | v0.3 |
| `tiling.focus` | `border`, `glow`, `none` | `"border"` | How the focused page is marked | v0.3 |
| `scroll.physics` | `native` | `"native"` | Always WebKit's; the key exists to say so | |
| `scroll.keys` | `smooth`, `instant` | `"smooth"` | Keyboard scrolling glides or jumps | v0.3 |
| `scroll.step` | 20–400 | `80` | Points per keyboard scroll step | v0.3 |
| `launcher.bangs.<name>` | URL with `%s` | none | Search shortcuts, used as `!name words` | |
| `downloads.dir` | a folder | `~/Downloads` | Where downloads are saved | |
| `[[space]] name` | text | the first site | Name of a starting Space | v0.2 |
| `[[space]] tint` | `sage blue sand clay plum slate` | next in turn | The Space's colour | v0.2 |
| `[[space]] jar` | text | own logins | Share logins with other Spaces using the same name | v0.2 |
| `[[space]] open` | addresses | none | Pages the Space opens with | v0.2 |
| `spaces.keep_archived` | a number of days | `30` | How long archived Spaces are kept | v0.2 |
| `history.retain` | a duration | a year | How long visits are kept | v0.2 |
| `history.snapshot` | `on-switch`, `idle`, `manual` | `"on-switch"` | When snapshots are taken | v0.3 |
| `pages.suspend_after` | a duration | 30 minutes | When hidden pages are put to sleep | v0.4 |
| `privacy.block` | list names | `["easylist", "easyprivacy"]` | Blocklists to apply | v0.4 |
| `updates.check` | `true`, `false` | `true` | Look for a new release once a day | v0.4 |
| `dev.inspectable` | `true`, `false` | `true` | Let Safari's Web Inspector attach to pages | v0.2 |
| `hud.enabled` | `true`, `false` | `false` | Show the performance HUD at launch | |

## Planned sections

| Section | Holds |
| --- | --- |
| `[privacy]` | Block categories, extra blocklists, third-party cookies, referrer policy |
| `[downloads]` | Folder and routing rules by file pattern |
| `[[userscript]]` | URL pattern and script file |
| `[keys]` bindings | Remapping any shortcut, one line per binding |

## Example

```toml
theme       = "graphite"
theme_light = "paper"

[keys]
mode = "standard"

[[space]]
name = "reading"
open = ["notes.example.org"]

[[space]]
name = "dev"
tint = "blue"
jar  = "work"
open = ["code.example.dev/common/browser/pulls", "localhost:5173"]
```
