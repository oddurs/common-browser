# Interface

At rest, only the page is visible. Everything else appears when called and leaves on its own.
Every action can be done three ways: from the menu bar, with a shortcut, or by typing a command in
the launcher.

## Surfaces

| Surface | Appears | Holds | Material |
| --- | --- | --- | --- |
| Window | Always | Pages; traffic lights top-left; a 36px title strip above tiled panes when windowed | Rounded 12px, macOS shadow and hairline; square in fullscreen |
| Capsule | Pointer at the top edge, or after a switch | Space colour, name and position ("Dev · 2 of 4"), site of the focused page, mode when not normal | Glass, 36px tall, radius 18 |
| Launcher | ⌘L, ⌘T, ⌘N | One field, grouped results with icon, title and site | Panel 640px wide, radius 18; the page behind blurs and dims |
| Space strip | Every Space switch, fades after 1.1s | A tile per Space drawn from its real layout; a frame glides to the current one | Glass, bottom centre |
| Overview | ⌘↑ | All Spaces as large tiles, New Space, recently closed Spaces | Full-window glass |
| Menu bar | Always when windowed; with the capsule in fullscreen | Every command with its shortcut | macOS menus, copper selection |
| Notifications | Config saves and errors, copies | Title, changed keys in mono, one sentence | Glass, top right, below the capsule |
| Link hints | ⌘J | One- or two-letter labels in the margin beside each link | Dark neutral chips, mono 11px |
| Keys sheet | ⌘/ | Every shortcut; vim keys dimmed until turned on | Panel, centred |
| Performance HUD | ⌥⌘P | Frame times, key-to-frame latency, pages, memory | Panel, bottom left |
| New-page start | ⌘T with nothing typed | Frequently visited sites as tiles with number keys | Follows light and dark |

## Materials

- **Glass:** the theme's deepest colour at 74% opacity with a 30px blur and 180% saturation. Used
  for the capsule, strip, notifications and overview.
- **Panel:** the theme background at 84–86% with a 40px blur. Used for the launcher, keys sheet
  and HUD.
- **Edges:** 0.5px hairlines, never heavier. Shadows are soft and large, as macOS draws them.
- **Radii:** window 12, capsule and launcher 18, tiled panes 14 (set by `window.corner`), menus 8,
  hint chips 5.
- **Focus:** the focused pane gets a 1.5px ring in the accent colour; unfocused panes dim by a 7%
  veil that fades in.

## Type

- The system font (SF Pro) for everything you read, at 13px for chrome.
- SF Mono only for key hints, code and config lines. URLs show the site name in SF Pro.
- Both are set in `[font]` and can be changed.

## Colour

The browser's own pair is the default: **graphite** for dark and **paper** for light, switching
with macOS appearance.

| Token | Graphite | Paper | Used for |
| --- | --- | --- | --- |
| Background | #1e1e20 | #f6f5f3 | Panels |
| Deep | #161618 | #eceae6 | Window, gaps, glass |
| Text | #ececee | #1d1d1f | Everything you read |
| Muted | #a1a1a6 | #6e6e73 | Secondary text |
| Accent (copper) | #d9895b | #b8643a | Caret, focus ring, strip frame, menu selection, nothing else |

Space colours are six quiet tints assigned in turn: sage, blue, sand, clay, plum, slate. A private
Space is always red. They appear only as small dots in the capsule, strip, overview and Window
menu.

Terminal themes can replace the pair: tokyo-night, catppuccin, gruvbox, nord, rose-pine,
everforest, catppuccin-latte, rose-pine-dawn. The prototype's `src/lib/themes.js` holds every
theme's tokens.

## Motion

One vocabulary: a spring-like ease-out, `cubic-bezier(0.32, 0.72, 0, 1)`, that settles fast
without bouncing.

| Token | Duration | Used for |
| --- | --- | --- |
| Fade | 140ms | Overlays in and out, focus veil, hover |
| Move | 220ms | Capsule, launcher settle, panes re-tiling |
| Space | 300ms | Sliding between Spaces, the strip frame |
| Window | 380ms | Windowed to fullscreen and back |

Rules:

- Everything that enters also leaves with motion.
- Panes animate only when the layout changes, never during a window resize.
- Keyboard scrolling eases by time, not by frame, so it feels the same at 60 and 120 Hz.
- With Reduce Motion on, every duration is zero.

## App icon

Four directions were drawn:

- **Prompt:** ›_
- **Tiles:** master and stack, with the focused pane lit.
- **Box b:** the letter drawn in box-drawing characters.
- **Momentum:** the decay curve, ending in a cursor.

None is chosen yet; see [open-questions.md](open-questions.md).

## Standard keymap

Standard Mac shortcuts are the default, and every one is in the menu bar. In the app, one command
table is the only place a shortcut is bound (`apps/macos/Sources/CommonApp/Commands.swift`).

| Keys | Does |
| --- | --- |
| ⌘L | Open location (the launcher) |
| ⌘T | New page, via the launcher |
| ⌘W | Close page; closing a Space's last page archives the Space |
| ⌘[  ⌘] | Back, forward |
| ⌘R | Reload |
| ⌘J  ⇧⌘J | Link hints; follow into a new page |
| ⇧⌘C | Copy link |
| ⌘N  ⇧⌘N | New Space; new private Space |
| ⌘1 – ⌘9 | Go to a Space by position |
| ⇧⌘[  ⇧⌘] | Previous, next Space |
| ⌘↑ | All Spaces |
| ⇧⌘1 – ⇧⌘9 | Send the focused page to a Space |
| ⌥⌘ arrows | Focus the page in that direction |
| ⇧⌥⌘ arrows | Move the page in that direction |
| ⌘\ | Next layout |
| ⌃⌘F | Full screen |
| ⌘, | Open common.toml in your editor |
| ⌘/ | Keys sheet |
| ⌥⌘P | Performance HUD |
| Esc | Close whatever is open: menu, keys sheet, overview, launcher, hints |

In the web prototype, ⌃ works in place of ⌘. The host browser keeps ⌘T, ⌘W and ⌘1–9 for itself.

## Vim layer

On with `keys.mode = "vim"`. It adds single-letter keys while no text field has focus; everything
above still works.

| Keys | Does |
| --- | --- |
| j  k | Scroll a step; holding glides |
| d  u | Half a page |
| gg  G | Top, bottom |
| H  L | Back, forward |
| f  F | Link hints; into a new page |
| o  O | Launcher; into a new page |
| :  @ | Launcher with a command or page search started |
| yy | Copy link |
| x | Close page |
| i | Focus the first text field |
| Esc | Leave a text field |

Modes exist only in the vim layer: NORMAL, INSERT (a text field has focus), HINT and LAUNCH. The
capsule names the mode only when it is not NORMAL.

## Launcher

One field, read by its first character.

| Typed | Finds |
| --- | --- |
| An address | Opens it |
| Words | Sites you know, open pages, then a web search |
| `@` | Open pages in every Space |
| `!gh words` | A search shortcut from `[launcher] bangs` |
| `:` | Commands: `:theme`, `:layout`, `:config`, `:hud`, `:help`, `:close`, `:log` |

Return opens in the current page; ⌥Return opens a new page; Tab completes a shortcut or command.
A site already open in this Space is left out of the list, but one open in another Space is
offered.

## Link hints

- Labels come from a home-row alphabet. They are prefix-free and as short as the count allows, so
  30 links get a mix of one and two letters.
- Labels sit in the margin just left of each link so the words stay readable. Links hard against
  the left edge get the label inside.
- Typing narrows the set, and the match follows immediately. Backspace undoes a letter, Esc
  cancels.

## Tiling

- Three layouts, cycled with ⌘\: master and stack (default ratio 0.58), columns, and one at a time.
- A single page, or the one-at-a-time layout, runs edge to edge with no gaps or corners.
- Moving focus picks the nearest page in that direction, centre to centre, with sideways drift
  counting double.
- In a window, tiled pages start below a 36px title strip so the traffic lights never sit on a
  page.

## Chrome behaviour

- The capsule appears when the pointer touches the top 4px of the window. It leaves
  `window.hide_after` (0.8s) after the pointer moves away.
- `window.chrome = "bar"` keeps a slim permanent bar instead; `"none"` shows chrome only for the
  launcher.
- Full screen hides the menu bar and traffic lights until the pointer reaches the top edge.

## Accessibility

- Every command is in the menu bar, so VoiceOver and Full Keyboard Access reach all of it.
- Single-letter shortcuts are off by default and can be turned off, as WCAG 2.1.4 asks.
- Focus is always visible; menus and the overview work with arrow keys, Return and Esc.
- Reduce Motion removes every animation.
- Every bundled theme keeps body text at 4.5:1 contrast or better. This still needs checking theme
  by theme.
