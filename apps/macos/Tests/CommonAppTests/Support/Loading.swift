import WebKit

/// Loads `html` into `webView` and waits for that navigation to finish, ignoring any load already
/// under way.
@MainActor
func load(_ webView: WKWebView, html: String) async throws {
  try await navigate(webView) { $0.loadHTMLString(html, baseURL: nil) }
}

/// Starts a navigation with `start` and waits for it to finish. The page's own navigation delegate
/// is set aside meanwhile and put back after.
@MainActor
func navigate(_ webView: WKWebView, _ start: (WKWebView) -> WKNavigation?) async throws {
  let waiter = NavigationWaiter()
  let original = webView.navigationDelegate
  webView.navigationDelegate = waiter
  defer { webView.navigationDelegate = original }
  try await withCheckedThrowingContinuation { continuation in
    waiter.continuation = continuation
    waiter.navigation = start(webView)
  }
}

@MainActor
private final class NavigationWaiter: NSObject, WKNavigationDelegate {
  var continuation: CheckedContinuation<Void, Error>?
  var navigation: WKNavigation?

  func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
    guard navigation === self.navigation else { return }
    continuation?.resume()
    continuation = nil
  }

  func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
    guard navigation === self.navigation else { return }
    continuation?.resume(throwing: error)
    continuation = nil
  }
}
