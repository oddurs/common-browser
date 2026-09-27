import WebKit

/// Downloads: what a page cannot show, or is told to save, goes to `Downloads.shared` instead of
/// replacing the page.
extension PageDelegate {
  public func webView(
    _ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction,
    decisionHandler: @escaping @MainActor @Sendable (WKNavigationActionPolicy) -> Void
  ) {
    // Set by `<a download>`, which asks for a save whatever the file's type.
    decisionHandler(navigationAction.shouldPerformDownload ? .download : .allow)
  }

  public func webView(
    _ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse,
    decisionHandler: @escaping @MainActor @Sendable (WKNavigationResponsePolicy) -> Void
  ) {
    let download = Self.shouldDownload(
      navigationResponse.response, canShowMIMEType: navigationResponse.canShowMIMEType)
    decisionHandler(download ? .download : .allow)
  }

  public func webView(
    _ webView: WKWebView, navigationAction: WKNavigationAction, didBecome download: WKDownload
  ) {
    download.delegate = Downloads.shared
  }

  public func webView(
    _ webView: WKWebView, navigationResponse: WKNavigationResponse,
    didBecome download: WKDownload
  ) {
    download.delegate = Downloads.shared
  }

  /// Whether a response is saved rather than shown: WebKit cannot display it, or the server says
  /// it is an attachment.
  nonisolated static func shouldDownload(_ response: URLResponse, canShowMIMEType: Bool) -> Bool {
    guard canShowMIMEType else { return true }
    let disposition = (response as? HTTPURLResponse)?.value(
      forHTTPHeaderField: "Content-Disposition")
    let type = disposition?.split(separator: ";").first?.trimmingCharacters(in: .whitespaces)
    return type?.lowercased() == "attachment"
  }
}
