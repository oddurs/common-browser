import Testing
import WebKit

@testable import CommonApp

@MainActor
@Test func closingTheLastPageLeavesAFreshPage() throws {
  let controller = BrowserWindowController(url: URL(string: "about:blank")!)
  let only = try #require(controller.currentWebView)
  controller.closePage(nil)
  let fresh = try #require(controller.currentWebView)
  #expect(fresh !== only)
  #expect(controller.pageCount == 1)
}

@MainActor
@Test func closingThePageOnScreenShowsTheNextOne() throws {
  let controller = BrowserWindowController(url: URL(string: "about:blank")!)
  let first = try #require(controller.currentWebView)
  controller.newPage(nil)
  let second = try #require(controller.currentWebView)
  controller.newPage(nil)
  controller.previousPage(nil)
  controller.closePage(nil)
  #expect(controller.currentWebView !== second)
  #expect(controller.pageCount == 2)
  controller.nextPage(nil)
  #expect(controller.currentWebView === first)
  #expect(first.superview != nil)
}

@MainActor
@Test func hiddenPagesKeepTheirFormContentsAndScrollPosition() async throws {
  let controller = BrowserWindowController(url: URL(string: "about:blank")!)
  let first = try #require(controller.currentWebView)
  try await load(first, html: "<input id=field><div style='height:5000px'></div>")
  _ = try await first.evaluateJavaScript(
    "document.getElementById('field').value = 'kept'; window.scrollTo(0, 800); 0")

  controller.newPage(nil)
  #expect(controller.currentWebView !== first)
  #expect(first.superview == nil)
  controller.previousPage(nil)
  #expect(controller.currentWebView === first)

  let state = try await first.evaluateJavaScript(
    "document.getElementById('field').value + ' ' + window.scrollY")
  #expect(state as? String == "kept 800")
}
