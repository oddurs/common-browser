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
  private let home: URL

  /// The page on screen.
  public var currentWebView: WKWebView? {
    pages.current().flatMap { webViews[$0] }
  }

  public var pageCount: Int { webViews.count }

  /// The key under which AppKit saves the window's frame between launches.
  static let frameName = "BrowserWindow"

  /// `home` is what a new page opens.
  public init(url: URL, home: URL = URL(string: "about:blank")!) {
    self.home = home
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

  public func newPage(_ sender: Any?) {
    openPage(home)
  }

  public func closePage(_ sender: Any?) {
    guard let id = pages.current() else { return }
    webViews.removeValue(forKey: id)?.removeFromSuperview()
    if let next = pages.close(id: id) {
      show(next)
    } else {
      // The window outlives its pages: closing the last one leaves a fresh page, not a closed
      // window, as the browser has no other place to type an address.
      newPage(sender)
    }
  }

  public func nextPage(_ sender: Any?) {
    show(pages.showNext())
  }

  public func previousPage(_ sender: Any?) {
    show(pages.showPrevious())
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
