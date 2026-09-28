import WebKit

/// Links with `target=_blank` and `window.open` open pages in this window rather than windows, and
/// `window.close()` closes the page. The new page shares its opener's process and keeps
/// `window.opener`, so a sign-in pop-up can report back to the site that opened it.
extension PageDelegate {
  public func webView(
    _ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration,
    for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures
  ) -> WKWebView? {
    windowController?.openPage(openedBy: webView, configuration: configuration)
  }

  public func webViewDidClose(_ webView: WKWebView) {
    windowController?.closePage(showing: webView)
  }
}
