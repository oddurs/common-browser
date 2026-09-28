# Configuration

Every setting lives in one file, `~/.config/common/common.toml` (`$XDG_CONFIG_HOME/common/common.toml`
when `XDG_CONFIG_HOME` is set). There is no settings window. Press ⌘, in the browser to open the
file; the first time, it is written for you with every setting commented out at its default.

A missing file, or a missing key, means the default. The browser reads the file when it starts.

## Keys

| Key | Type | Default | What it does |
| --- | --- | --- | --- |
| `home` | an address with a scheme | `"about:blank"` | The page a new window or page opens |
| `theme` | `"graphite"` or `"paper"` | `"graphite"` | The theme in dark mode |
| `theme_light` | `"graphite"` or `"paper"` | `"paper"` | The theme in light mode |
| `accent` | a colour, `"#rrggbb"` | `"#d9895b"` | The accent colour |
| `window.start` | `"windowed"` or `"fullscreen"` | `"windowed"` | How the window first appears |
| `search.engine` | an address containing `%s` | `"https://duckduckgo.com/?q=%s"` | Where launcher searches go; `%s` becomes what you typed |
| `keys.mode` | `"standard"` | `"standard"` | Which shortcuts to use. Vim keys arrive in v0.3. |

## Example

```toml
home = "https://news.ycombinator.com"
accent = "#3b82f6"

[window]
start = "fullscreen"

[search]
engine = "https://kagi.com/search?q=%s"
```

## Mistakes

A key with a mistake keeps its default, and every other key still applies. The browser shows a
banner naming the first mistake and its line. To see every mistake at once, run:

```sh
common config check
```

It prints one line per mistake as `FILE:LINE:COLUMN: MESSAGE`, with a suggestion when a key looks
misspelt, and exits 1 if there are any:

```
/Users/you/.config/common/common.toml:3:1: unknown key `thme` (did you mean `theme`?)
```

The full design, including the keys planned for later releases, is in
[design/config.md](design/config.md).
