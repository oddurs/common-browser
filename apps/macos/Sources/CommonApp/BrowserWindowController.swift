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

  /// The page on screen.
  public var currentWebView: WKWebView? {
    pages.current().flatMap { webViews[$0] }
  }

  public var pageCount: Int { webViews.count }

  public init(url: URL) {
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
    window.center()
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
    openPage(URL(string: "about:blank")!)
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
    for view in container.subviews where view !== webView {
      view.removeFromSuperview()
    }
    if webView.superview !== container {
      webView.frame = container.bounds
      webView.autoresizingMask = [.width, .height]
      container.addSubview(webView)
    }
    window?.makeFirstResponder(webView)
  }
}
