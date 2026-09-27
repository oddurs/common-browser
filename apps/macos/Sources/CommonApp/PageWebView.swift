import WebKit

/// Every page's web view is made here, so what all pages share is set in one place.
@MainActor
public func makePageWebView(delegate: PageDelegate) -> WKWebView {
  let webView = WKWebView()
  webView.navigationDelegate = delegate
  webView.uiDelegate = delegate
  return webView
}

/// Answers WebKit's questions for the pages of one window: dialogs, downloads, new windows. The
/// class is declared once here and each feature adds its delegate methods in an extension in its
/// own file (`PageDelegate+Dialogs.swift` and so on), so features stay apart and can land
/// independently.
@MainActor
public final class PageDelegate: NSObject, WKNavigationDelegate, WKUIDelegate {}
