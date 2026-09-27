# Common Browser prototype

A web stand-in for the macOS app, to try the interaction model before writing Swift.
Pages are local fakes in `static/site/`; the shell around them is the thing being tested.

```sh
npm install
npm run dev        # http://127.0.0.1:5317
```

Edit `common.toml` in any editor and save: the open browser applies it and reports errors
with a line number. `⌥,` asks the dev server to open the file (`open -t` on macOS; set
`COMMON_EDITOR="zed"` or similar to choose). `COMMON_CONFIG=/path/to/file.toml` points at
another config.

Press `?` in the browser for every key. Click into the page once so it has keyboard focus.

What the prototype cannot show: WebKit's native scroll (it scrolls however your browser
does), real cookie isolation per jar, and most outside sites, which refuse to load in a frame.
