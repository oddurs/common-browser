import Testing
import WebKit

@testable import CommonApp

@MainActor
@Test func aPageWebViewLoadsHTMLAndRunsItsScripts() async throws {
  let delegate = PageDelegate()
  let webView = makePageWebView(delegate: delegate)
  // The inline script only changes the title if the configuration lets pages run JavaScript.
  try await load(webView, html: "<title>smoke</title><script>document.title += ' ok'</script>")
  #expect(try await webView.evaluateJavaScript("document.title") as? String == "smoke ok")
  #expect(try await webView.evaluateJavaScript("6 * 7") as? Int == 42)
}

@MainActor
@Test func aPageWebViewReportsToTheWindowsDelegate() {
  let delegate = PageDelegate()
  let webView = makePageWebView(delegate: delegate)
  #expect(webView.navigationDelegate === delegate)
  #expect(webView.uiDelegate === delegate)
}
