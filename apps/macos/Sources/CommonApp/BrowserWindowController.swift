import AppKit
import CommonCore
import WebKit

/// One browser window. AppKit places a window controller in the responder chain after the window,
/// so this is where `BrowserActions` the page does not handle itself end up.
///
/// The order of pages and which one is visible belong to the core's `PageList`; this class keeps a
/// web view per page and shows the one the list says is current.
@MainActor
public final class BrowserWindowController: NSWindowController, BrowserActions {
  private let pages = PageList()
  private var webViews: [UInt64: WKWebView] = [:]
  private let pageDelegate = PageDelegate()
  private let container = NSView()
  let find = FindState()
  let launcher: LauncherState
  private let home: URL

  /// The page on screen.
  public var currentWebView: WKWebView? {
    pages.current().flatMap { webViews[$0] }
  }

  public var pageCount: Int { webViews.count }

  /// The key under which AppKit saves the window's frame between launches.
  static let frameName = "BrowserWindow"

  /// `home` is what a new page opens; `searchEngine` is where launcher searches go, a URL template
  /// with `%s` for the terms.
  public init(
    url: URL, home: URL = URL(string: "about:blank")!,
    searchEngine: String = defaultSettings().searchEngine
  ) {
    self.home = home
    launcher = LauncherState(searchEngine: searchEngine)
    // The page owns the window: no toolbar, a transparent title bar, content under it.
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 1280, height: 800),
      styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
      backing: .buffered,
      defer: false
    )
    window.titlebarAppearsTransparent = true
    window.titleVisibility = .hidden
    window.contentView = container
    window.collectionBehavior.insert(.fullScreenPrimary)
    if !window.setFrameUsingName(Self.frameName) {
      window.center()
    }
    window.setFrame(
      fitted(window.frame, into: NSScreen.screens.map(\.visibleFrame)), display: false)
    // AppKit refuses a name another window already holds, so only the first window's frame is
    // remembered; v0.1 has one window.
    window.setFrameAutosaveName(Self.frameName)
    super.init(window: window)
    pageDelegate.windowController = self
    openPage(url)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("BrowserWindowController is created in code")
  }

  /// Opens `url` in a new page at the end and shows it.
  @discardableResult
  public func openPage(_ url: URL) -> WKWebView {
    let webView = makePageWebView(delegate: pageDelegate)
    webViews[pages.open()] = webView
    webView.load(URLRequest(url: url))
    show(pages.current())
    return webView
  }

  /// Adds the page a page's script or link asked for, right after `opener`, and shows it. WebKit
  /// loads it, so it is returned empty.
  func openPage(openedBy opener: WKWebView, configuration: WKWebViewConfiguration) -> WKWebView {
    let webView = makePageWebView(delegate: pageDelegate, configuration: configuration)
    let id = id(of: opener).map { pages.openAfter(opener: $0) } ?? pages.open()
    webViews[id] = webView
    show(pages.current())
    return webView
  }

  /// Closes the page that shows `webView`, as when its script calls `window.close()`.
  func closePage(showing webView: WKWebView) {
    if let id = id(of: webView) { close(id) }
  }

  /// ⌘T: a new page, with the launcher open on it.
  public func newPage(_ sender: Any?) {
    openPage(home)
    showLauncher()
  }

  public func closePage(_ sender: Any?) {
    if let id = pages.current() { close(id) }
  }

  private func close(_ id: UInt64) {
    webViews.removeValue(forKey: id)?.removeFromSuperview()
    if let next = pages.close(id: id) {
      show(next)
    } else {
      // The window outlives its pages: closing the last one leaves a fresh page, not a closed
      // window, as the browser has no other place to type an address.
      newPage(nil)
    }
  }

  private func id(of webView: WKWebView) -> UInt64? {
    webViews.first { $0.value === webView }?.key
  }

  public func nextPage(_ sender: Any?) {
    show(pages.showNext())
  }

  public func previousPage(_ sender: Any?) {
    show(pages.showPrevious())
  }

  /// The pages in order.
  var pageIDs: [UInt64] { pages.ids() }

  func webView(for id: UInt64) -> WKWebView? { webViews[id] }

  /// Makes `id` the page on screen.
  func showPage(_ id: UInt64) {
    if pages.select(id: id) { show(id) }
  }

  /// Puts the page's web view on screen. Hidden pages stay alive, off screen, so they keep their
  /// scroll position, form contents and running scripts.
  private func show(_ id: UInt64?) {
    guard let id, let webView = webViews[id] else { return }
    for view in container.subviews where view is WKWebView && view !== webView {
      view.removeFromSuperview()
    }
    if webView.superview !== container {
      webView.frame = container.bounds
      webView.autoresizingMask = [.width, .height]
      // Below the find bar and anything else that floats over the page.
      container.addSubview(webView, positioned: .below, relativeTo: nil)
    }
    closeFind()
    window?.makeFirstResponder(webView)
  }

  /// Pins a notice about `common.toml` to the top of the window, over every page.
  public func showConfigBanner(_ text: String) {
    let banner = ConfigBanner(text: text)
    container.addSubview(banner)
    NSLayoutConstraint.activate([
      banner.topAnchor.constraint(equalTo: container.topAnchor, constant: 10),
      banner.centerXAnchor.constraint(equalTo: container.centerXAnchor),
      banner.widthAnchor.constraint(lessThanOrEqualTo: container.widthAnchor, constant: -160),
    ])
  }
}
