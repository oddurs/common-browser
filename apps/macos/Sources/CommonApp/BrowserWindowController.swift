import AppKit
import WebKit

/// One browser window. AppKit places a window controller in the responder chain after the window,
/// so this is where `BrowserActions` the page does not handle itself end up.
@MainActor
public final class BrowserWindowController: NSWindowController, BrowserActions {
  public let webView = WKWebView()

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
    window.contentView = webView
    window.center()
    super.init(window: window)
    webView.load(URLRequest(url: url))
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("BrowserWindowController is created in code")
  }
}
