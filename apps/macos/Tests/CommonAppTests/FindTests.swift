import Testing
import WebKit

@testable import CommonApp

private let twelve = """
  <p>one fox</p><p>two fox</p><p>three Fox</p><p>four fox</p><p>five fox</p><p>six fox</p>
  <p>seven fox</p><p>eight fox</p><p>nine fox</p><p>ten fox</p><p>eleven fox</p><p>twelve fox</p>
  """

@MainActor
private func page(_ html: String) async throws -> WKWebView {
  let webView = makePageWebView(delegate: PageDelegate())
  try await load(webView, html: html)
  return webView
}

@MainActor
@Test func findCountsTheMatchesAndMovesThroughThem() async throws {
  let webView = try await page(twelve)
  #expect(await findInPage(webView, "fox") == .match(index: 1, count: 12))
  #expect(await findInPage(webView, "fox") == .match(index: 2, count: 12))
  #expect(await findInPage(webView, "fox") == .match(index: 3, count: 12))
  #expect(await findInPage(webView, "fox", backwards: true) == .match(index: 2, count: 12))
}

@MainActor
@Test func findWrapsAround() async throws {
  let webView = try await page(twelve)
  #expect(await findInPage(webView, "fox", backwards: true) == .match(index: 12, count: 12))
  #expect(await findInPage(webView, "fox") == .match(index: 1, count: 12))
}

@MainActor
@Test func findSaysWhenNothingMatches() async throws {
  let webView = try await page(twelve)
  #expect(await findInPage(webView, "wolf") == .noMatches)
  #expect(await findInPage(webView, "") == .idle)
}

@MainActor
@Test func typingMoreOfTheQueryStaysOnTheSameMatch() async throws {
  let webView = try await page("<p>alpha</p><p>alpine</p><p>alps</p>")
  #expect(await findInPage(webView, "al") == .match(index: 1, count: 3))
  #expect(await findInPage(webView, "al") == .match(index: 2, count: 3))
  #expect(await findInPage(webView, "alp") == .match(index: 2, count: 3))
  #expect(await findInPage(webView, "alpi") == .match(index: 1, count: 1))
}

/// The highlight checks run in find's own world. Asked from the page's world, `CSS.highlights`
/// kept reporting highlights that find had already deleted, once the page had looked at them.
@MainActor
@Test func theCurrentMatchIsSelectedAndEveryMatchHighlighted() async throws {
  let webView = try await page(twelve)
  _ = await findInPage(webView, "fox")
  _ = await findInPage(webView, "fox")
  let selected = try await webView.evaluateJavaScript(
    "getSelection().toString() + ' ' + getSelection().anchorNode.textContent")
  #expect(selected as? String == "fox two fox")
  let highlighted = try await webView.callAsyncJavaScript(
    "return CSS.highlights.get('common-find').size", contentWorld: findWorld)
  #expect(highlighted as? Int == 12)
  await clearFindHighlights(webView)
  let cleared = try await webView.callAsyncJavaScript(
    "return CSS.highlights.has('common-find')", contentWorld: findWorld)
  #expect(cleared as? Bool == false)
  #expect(try await webView.evaluateJavaScript("getSelection().toString()") as? String == "fox")
}

@Test func theStatusReadsAsTheBarShowsIt() {
  #expect(FindStatus.match(index: 3, count: 12).text == "3 of 12")
  #expect(FindStatus.match(index: 3, count: countLimit).text == "3 of 1000+")
  #expect(FindStatus.noMatches.text == "No matches")
  #expect(FindStatus.idle.text == "")
}

@MainActor
private func type(_ query: String, into bar: FindBar) {
  bar.field.stringValue = query
  bar.controlTextDidChange(Notification(name: NSControl.textDidChangeNotification))
}

@MainActor
private func press(_ selector: Selector, in bar: FindBar) -> Bool {
  bar.control(bar.field, textView: NSTextView(), doCommandBy: selector)
}

@MainActor
@Test func theBarShowsTheCountAndSteps() async throws {
  let controller = BrowserWindowController(url: URL(string: "about:blank")!)
  try await load(try #require(controller.currentWebView), html: twelve)
  let bar = controller.find.bar

  controller.showFind(nil)
  #expect(!bar.isHidden)
  #expect(controller.window?.firstResponder === bar.field.currentEditor())

  type("fox", into: bar)
  await controller.find.settle()
  #expect(bar.statusLabel.stringValue == "1 of 12")

  controller.findNextMatch(nil)
  await controller.find.settle()
  #expect(bar.statusLabel.stringValue == "2 of 12")

  #expect(press(#selector(NSResponder.insertNewline(_:)), in: bar))
  await controller.find.settle()
  #expect(bar.statusLabel.stringValue == "3 of 12")

  controller.findPreviousMatch(nil)
  await controller.find.settle()
  #expect(bar.statusLabel.stringValue == "2 of 12")

  type("wolf", into: bar)
  await controller.find.settle()
  #expect(bar.statusLabel.stringValue == "No matches")
}

@MainActor
@Test func escClosesTheBarAndLeavesTheMatchSelectedInTheFocusedPage() async throws {
  let controller = BrowserWindowController(url: URL(string: "about:blank")!)
  let webView = try #require(controller.currentWebView)
  try await load(webView, html: twelve)
  let bar = controller.find.bar
  controller.showFind(nil)
  type("fox", into: bar)
  await controller.find.settle()

  #expect(press(#selector(NSResponder.cancelOperation(_:)), in: bar))
  await controller.find.settle()
  #expect(bar.isHidden)
  #expect(controller.window?.firstResponder === webView)
  #expect(try await webView.evaluateJavaScript("getSelection().toString()") as? String == "fox")
  let highlighted = try await webView.callAsyncJavaScript(
    "return CSS.highlights.has('common-find')", contentWorld: findWorld)
  #expect(highlighted as? Bool == false)
}

@MainActor
@Test func findNextWithNothingToFindOpensTheBar() {
  let controller = BrowserWindowController(url: URL(string: "about:blank")!)
  controller.findNextMatch(nil)
  #expect(!controller.find.bar.isHidden)
  #expect(controller.window?.firstResponder === controller.find.bar.field.currentEditor())
}

@MainActor
@Test func switchingPagesClosesTheBar() {
  let controller = BrowserWindowController(url: URL(string: "about:blank")!)
  controller.showFind(nil)
  controller.newPage(nil)
  #expect(controller.find.bar.isHidden)
  #expect(controller.find.bar.superview != nil)
}

@MainActor
@Test func theBarSitsAtTheTopCentreBelowTheTitleBar() throws {
  let controller = BrowserWindowController(url: URL(string: "about:blank")!)
  controller.showFind(nil)
  let content = try #require(controller.window?.contentView)
  content.layoutSubtreeIfNeeded()
  let bar = controller.find.bar.frame
  #expect(abs(bar.midX - content.bounds.midX) < 1)
  #expect(bar.maxY <= content.safeAreaRect.maxY)
  #expect(bar.maxY > content.bounds.maxY - 80)
  #expect(bar.height == FindBar.height)
}

@MainActor
@Test func aPageLeftBehindLosesItsHighlights() async throws {
  let controller = BrowserWindowController(url: URL(string: "about:blank")!)
  let first = try #require(controller.currentWebView)
  try await load(first, html: twelve)
  controller.showFind(nil)
  type("fox", into: controller.find.bar)
  await controller.find.settle()
  // A search queued straight after the switch must not overtake the clean-up of the old page.
  controller.newPage(nil)
  controller.findNextMatch(nil)
  await controller.find.settle()
  let highlighted = try await first.callAsyncJavaScript(
    "return CSS.highlights.has('common-find')", contentWorld: findWorld)
  #expect(highlighted as? Bool == false)
}
