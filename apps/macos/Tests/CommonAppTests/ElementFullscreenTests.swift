import Testing
import WebKit

@testable import CommonApp

/// What a video player looks for before it offers a full-screen button.
private let fullscreenSupport =
  "typeof document.documentElement.requestFullscreen + ' ' + document.fullscreenEnabled"

@MainActor
@Test func pagesCanShowAnElementFullScreen() async throws {
  let webView = makePageWebView(delegate: PageDelegate())
  #expect(webView.configuration.preferences.isElementFullscreenEnabled)
  try await load(webView, html: "<video></video>")
  #expect(try await webView.evaluateJavaScript(fullscreenSupport) as? String == "function true")
}

@MainActor
@Test func aPlainWebViewHidesTheFullscreenAPI() async throws {
  // The control for the test above: WKWebView's default leaves pages no full-screen API at all.
  let webView = WKWebView()
  try await load(webView, html: "<video></video>")
  let support = try await webView.evaluateJavaScript(fullscreenSupport) as? String
  #expect(support == "undefined undefined")
}
