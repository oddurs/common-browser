import WebKit

/// Loads `html` into `webView` and waits for that navigation to finish, ignoring any load already
/// under way. The page's own navigation delegate is set aside for the load and put back after.
@MainActor
func load(_ webView: WKWebView, html: String) async throws {
  let waiter = NavigationWaiter()
  let original = webView.navigationDelegate
  webView.navigationDelegate = waiter
  defer { webView.navigationDelegate = original }
  try await withCheckedThrowingContinuation { continuation in
    waiter.continuation = continuation
    waiter.navigation = webView.loadHTMLString(html, baseURL: nil)
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
