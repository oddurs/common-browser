# Architecture

Common Browser has no engine of its own. The work is the shell around the platform's web view, and
everything that does not need a window lives in a Rust core that every shell shares. The macOS
shell is a Swift 6 AppKit app with one `WKWebView` per page, for macOS 14 and later.

## Pieces

| Piece | Holds | Built on |
| --- | --- | --- |
| `crates/common-core` | Config parsing and validation, the page model, and later the keymap engine, tiling layout, Spaces and history | Rust, no UI toolkit, no web engine, no platform API |
| `crates/common-ffi` | The core as Swift sees it: records, objects and errors | UniFFI, a static library |
| `crates/common-cli` | The `common` command: `config check`, later `space list` and `export` | `common-core` |
| `apps/macos` | Window, menus, pages, launcher, capsule, strip, overview, notifications | Swift 6, AppKit, WebKit |
| Linux and Windows shells | The same browser on GTK + WebKitGTK and on WebView2 | Rust, calling `common-core` directly; after v1.0 |

The core stays free of platform code so it tests without a window and serves every shell alike.
If something cannot be unit-tested without a window, it belongs in a shell.

## Components of the macOS shell

| Component | Responsibility | Built on |
| --- | --- | --- |
| Window | Full screen and windowed, hidden title bar, traffic lights, title strip in tiled windows | `NSWindow`, full-size content view |
| Chrome surfaces | Capsule, launcher, strip, overview, notifications, HUD | `NSVisualEffectView`, Core Animation layers |
| Menu bar | Every command with its shortcut; the single source of shortcuts | `NSMenu` built from the command table |
| Page | Navigation, find, zoom, focus and scroll events | `WKWebView`, user scripts, script message handlers |
| Tiling | Layout tree, gaps, ratios, directional focus | `common-core` |
| Spaces | Line of Spaces, archive, restore, private, jars | `common-core` model, one data store per jar |
| Input | Standard keymap, vim layer, modes | Menu key equivalents, plus a local key monitor for the vim layer |
| Link hints | Visible clickable elements and their positions | One injected script pass; labels drawn natively |
| Content blocking | Blocklists compiled once and cached | `WKContentRuleListStore` |
| Config | Watch, parse, validate, diff, apply, report | `common-core`; a watcher on the config folder |
| History | Visits, page tree, snapshots, frecency | SQLite with FTS5 for launcher search |

## Pipelines

- **Keys.** Menu key equivalents handle every ⌘ shortcut, which keeps shortcuts and menus from
  drifting apart. The vim layer uses a local key monitor and acts only when no text field has
  focus. An injected script reports focus changes in the page, which is how INSERT mode is known.
- **Config.** A watcher on `~/.config/common/` triggers parse, validate, diff and apply. It watches
  the folder, so editors that save by rename still count. Each key is validated on its own; a bad
  key keeps its previous value and reports its line. The diff is what the notification lists. The
  same code runs in `common config check`.
- **Spaces.** Every page's view stays alive when its Space is not shown. Switching hides and shows
  views, so a return is instant and keeps scroll position. Pages idle for a long time can be put
  to sleep and restored from their snapshot.
- **Scrolling.** WebKit's scrolling stays entirely native. Keyboard scrolling is a small injected
  script that glides by time and stops the moment a gesture begins.

## Storage

| Path | Holds |
| --- | --- |
| `~/.config/common/common.toml` | Settings (`$XDG_CONFIG_HOME` respected) |
| `~/.config/common/themes/*.toml` | Extra themes |
| `~/.config/common/scripts/` | Userscripts named in the config |
| `~/Library/Application Support/Common/common.db` | Visits, pages, Spaces, snapshots |
| WebKit data stores | Cookies and site data, one per jar |

## Performance

Speed is part of the product: the browser should never be the slow part. These are proposed
budgets, not measurements; item `5321df17` (v0.4) measures them on real hardware and adjusts them.

| Moment | Budget | Measured by |
| --- | --- | --- |
| Cold launch to a usable window | 300 ms or less | Launch metric |
| Key press to its effect on screen (launcher, Space switch start) | Within the next frame: 8.3 ms at 120 Hz, 16.7 ms at 60 Hz | Signposts, HUD |
| Space switch animation | 300 ms with no dropped frames | Signposts, HUD frame graph |
| Launcher results while typing | Next frame, from an in-memory index | Signposts |
| Config save to applied | 16 ms or less for a valid file | Unit timing in the core |
| Browser chrome memory, not counting web content | Tens of MB, to be pinned after measuring | Instruments |

How it stays fast:

1. **Don't own the scroll.** WebKit scrolls on its compositor thread; nothing of ours runs in that
   path.
2. **Native chrome.** Every surface is AppKit and Core Animation; there are no web views in the
   chrome, so opening the launcher never waits on JavaScript.
3. **Keep, then sleep.** Pages in other Spaces stay alive but hidden, so switching is a visibility
   flip. Pages idle for long periods sleep and wake from their snapshot.
4. **Compile once.** Blocklists compile into WebKit rule lists at install or change, then load from
   cache.
5. **Index ahead.** Launcher search reads an in-memory index built from SQLite (FTS5) at launch and
   updated on each visit.
6. **One pass for hints.** A single injected script returns every clickable element's position;
   labels are drawn natively.
7. **Animate cheap properties.** Motion uses transform and opacity; panes only re-tile on layout
   changes, never on window resize.

Measuring:

- **HUD (⌥⌘P):** frame times at the display's refresh rate, key-to-frame latency, pages open,
  memory, network per page.
- **Signposts:** every key path (launch, key to launcher, Space switch, config apply) is wrapped in
  `os_signpost`, so Instruments and CI see the same intervals.

Known costs:

| Cost | Why | Plan |
| --- | --- | --- |
| Blur behind the launcher and overview | Blurring live pages costs GPU time on large displays | Measure first; fall back to a plain dim if frames drop |
| Many content processes | WebKit runs a process per page | Sleep idle pages; show per-jar totals |
| Per-page memory | WebKit does not expose it publicly | Report per-jar process totals, labelled as estimates |
| Moving a page between Spaces | Must keep the same view to avoid a reload | Reparent the web view instead of recreating it |

## Privacy and security

The browser keeps your data on your computer and sends nothing home. Separation between Spaces is
the main privacy tool, and it is on by default.

Logins and site data:

- Each Space has its own WebKit data store. Cookies, local storage, caches and service workers
  never cross Spaces unless they share a jar by name.
- Private Spaces use a memory-only store. They record no visits and take no snapshots, and closing
  the last page discards everything.
- Permission answers (camera, microphone, location, notifications) are stored per jar, so allowing
  a site in Work does not allow it in Personal.

Blocking:

- Trackers and cryptominers are blocked by default through WebKit content rule lists, compiled
  once and cached.
- Extra blocklists can be named in `[privacy]`. Third-party cookies are off by default, and the
  referrer is trimmed to the origin.
- Chrome and Firefox extensions are not supported; userscripts and blocklists cover the common
  needs.

What the app sends:

- No telemetry, no accounts, no sync service.
- Crash logs stay local and are attached to bug reports by hand.
- Update checks read the project's release page and carry no identifier.

Userscripts:

- Only scripts in `~/.config/common/scripts/` and named in `[[userscript]]` run, each limited to
  its URL pattern.
- A script that fails to load is reported like a config error, with its path.

Distribution:

- Signed with a Developer ID and notarised, built with the hardened runtime. v0.1 ships ad-hoc
  signed; see the signing spike, `363132d3`.
- Shipped on GitHub Releases and as a Homebrew cask. Not on the Mac App Store, because the sandbox
  would block opening your editor and reading `~/.config/common/`.
