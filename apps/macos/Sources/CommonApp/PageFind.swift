import WebKit

/// What a search found, as the find bar shows it.
public enum FindStatus: Equatable, Sendable {
  /// Nothing searched for yet.
  case idle
  case noMatches
  /// `index` is 1-based. `count` stops at `countLimit`, which the bar shows as "1000+".
  case match(index: Int, count: Int)
  /// WebKit found a match the count could not see, such as one inside a frame.
  case uncounted

  public var text: String {
    switch self {
    case .idle: ""
    case .noMatches: "No matches"
    case .match(let index, let count) where count >= countLimit: "\(index) of \(countLimit)+"
    case .match(let index, let count): "\(index) of \(count)"
    case .uncounted: "Found"
    }
  }
}

/// Counting stops here: past it the number is not useful and the count starts to cost time.
let countLimit = 1000

/// Find's scripts run in their own world, so the page's scripts cannot see or change them.
@MainActor let findWorld = WKContentWorld.world(name: "common-find")

/// Moves to the next (or previous) match of `query` in `webView`, then counts the matches and
/// highlights them all.
///
/// WebKit's find selects and reveals a match but only says whether one exists. The count comes
/// from `window.find`, which runs WebKit's own matcher, so the count and WebKit agree on what a
/// match is. A script matching `textContent` itself would have to reimplement WebKit's rules for
/// case, whitespace and text split across elements, and would drift from them.
@MainActor
public func findInPage(_ webView: WKWebView, _ query: String, backwards: Bool = false) async
  -> FindStatus
{
  guard !query.isEmpty else {
    await clearFindHighlights(webView)
    return .idle
  }
  let configuration = WKFindConfiguration()
  configuration.backwards = backwards
  let found = await withCheckedContinuation { continuation in
    webView.find(query, configuration: configuration) { continuation.resume(returning: $0) }
  }
  guard found.matchFound else {
    await clearFindHighlights(webView)
    return .noMatches
  }
  let result = try? await webView.callAsyncJavaScript(
    countScript, arguments: ["query": query, "limit": countLimit], contentWorld: findWorld)
  guard let counted = result as? [String: Any],
    let count = counted["count"] as? Int, let index = counted["index"] as? Int,
    count > 0
  else { return .uncounted }
  return .match(index: min(max(index, 1), count), count: count)
}

/// Removes the highlights of every match, leaving the current match selected.
@MainActor
public func clearFindHighlights(_ webView: WKWebView) async {
  // A page that has navigated away or crashed has no highlights left to clear.
  _ = try? await webView.callAsyncJavaScript(clearScript, contentWorld: findWorld)
}

/// Walks the document with `window.find` from the start, collecting a range per match, then puts
/// back the selection and scroll position WebKit's find left. `window.find` moves both as it goes,
/// but a script runs to the end before the page paints again, so those moves are never drawn.
private let countScript = """
  const selection = getSelection();
  const current = selection.rangeCount ? selection.getRangeAt(0).cloneRange() : null;
  const x = scrollX, y = scrollY;
  const ranges = [];
  selection.removeAllRanges();
  while (ranges.length < limit && window.find(query, false, false, false, false, false, false)) {
    const range = selection.getRangeAt(0).cloneRange();
    const last = ranges[ranges.length - 1];
    if (last && range.compareBoundaryPoints(Range.START_TO_START, last) <= 0) break;
    ranges.push(range);
  }
  selection.removeAllRanges();
  if (current) selection.addRange(current);
  scrollTo(x, y);

  let index = 0;
  if (current) {
    for (const range of ranges) {
      try {
        if (range.compareBoundaryPoints(Range.START_TO_START, current) <= 0) index++;
      } catch {}
    }
  }

  if (window.CSS && CSS.highlights) {
    globalThis.findSheet ??= (() => {
      const sheet = new CSSStyleSheet();
      sheet.replaceSync(`
        ::highlight(common-find) { background-color: rgb(255 222 90 / 0.6); color: black; }
        ::highlight(common-find-current) { background-color: rgb(255 150 50); color: black; }
      `);
      return sheet;
    })();
    if (!document.adoptedStyleSheets.includes(findSheet)) {
      document.adoptedStyleSheets = [...document.adoptedStyleSheets, findSheet];
    }
    CSS.highlights.set('common-find', new Highlight(...ranges));
    CSS.highlights.set('common-find-current', current ? new Highlight(current) : new Highlight());
  }
  return { count: ranges.length, index };
  """

private let clearScript = """
  if (window.CSS && CSS.highlights) {
    CSS.highlights.delete('common-find');
    CSS.highlights.delete('common-find-current');
  }
  if (globalThis.findSheet) {
    document.adoptedStyleSheets = document.adoptedStyleSheets.filter((s) => s !== findSheet);
  }
  """
