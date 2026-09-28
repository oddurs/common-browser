import AppKit
import Testing
import WebKit

@testable import CommonApp

// Searches go to a file URL, so no test reaches the network.
private let engine = "file:///nonexistent/search?q=%s"

@MainActor
private func window() -> BrowserWindowController {
  BrowserWindowController(url: URL(string: "about:blank")!, searchEngine: engine)
}

@MainActor
private func type(_ text: String, in controller: BrowserWindowController) {
  let panel = controller.launcher.panel
  panel.field.stringValue = text
  panel.controlTextDidChange(
    Notification(name: NSControl.textDidChangeNotification, object: panel.field))
}

/// Sends an editing command, as AppKit does for Return, Esc and the arrow keys.
@MainActor
private func press(_ command: Selector, in controller: BrowserWindowController) {
  let panel = controller.launcher.panel
  _ = panel.control(panel.field, textView: NSTextView(), doCommandBy: command)
}

@MainActor
@Test func anAddressStartsLoadingWithinTheReturnKeysOwnEvent() throws {
  let controller = window()
  let page = try #require(controller.currentWebView)
  controller.openLocation(nil)
  type("file:///tmp/common-launcher-test.html", in: controller)
  #expect(
    controller.launcher.panel.rows.first == .go("Go to file:///tmp/common-launcher-test.html"))

  press(#selector(NSResponder.insertNewline(_:)), in: controller)
  // No waiting: the page has its new address before Return's handler has returned.
  #expect(page.url?.absoluteString == "file:///tmp/common-launcher-test.html")
  #expect(!controller.isLauncherOpen)
}

@MainActor
@Test func wordsSearchWithTheConfiguredEngine() throws {
  let controller = window()
  let page = try #require(controller.currentWebView)
  controller.openLocation(nil)
  type("what is rust", in: controller)
  #expect(controller.launcher.panel.rows.first == .go("Search for what is rust"))
  press(#selector(NSResponder.insertNewline(_:)), in: controller)
  #expect(page.url?.absoluteString == "file:///nonexistent/search?q=what+is+rust")
}

@MainActor
@Test func openPagesAreFoundByTitleAndPickedWithTheArrowsAndReturn() async throws {
  let controller = window()
  let docs = try #require(controller.currentWebView)
  try await load(docs, html: "<title>Rust docs</title>")
  controller.newPage(nil)
  let mail = try #require(controller.currentWebView)
  try await load(mail, html: "<title>Mail</title>")

  controller.openLocation(nil)
  type("rust", in: controller)
  let rows = controller.launcher.panel.rows
  #expect(rows.count == 2)
  #expect(rows.first == .go("Search for rust"))
  guard case .page(_, let title, _)? = rows.last else {
    Issue.record("no page row: \(rows)")
    return
  }
  #expect(title == "Rust docs")

  press(#selector(NSResponder.moveDown(_:)), in: controller)
  press(#selector(NSResponder.insertNewline(_:)), in: controller)
  #expect(controller.currentWebView === docs)
  #expect(!controller.isLauncherOpen)
}

@MainActor
@Test func escHandsFocusBackToWhatHadIt() async throws {
  let controller = window()
  let page = try #require(controller.currentWebView)
  // A web view still starting its content process can turn focus away.
  try await load(page, html: "<p>page</p>")
  let window = try #require(controller.window)
  window.makeFirstResponder(page)
  #expect(window.firstResponder === page)

  controller.openLocation(nil)
  #expect(controller.isLauncherOpen)
  #expect(window.firstResponder !== page)

  press(#selector(NSResponder.cancelOperation(_:)), in: controller)
  #expect(!controller.isLauncherOpen)
  #expect(window.firstResponder === page)
}

@MainActor
@Test func aNewPageOpensWithTheLauncher() {
  let controller = window()
  controller.newPage(nil)
  #expect(controller.pageCount == 2)
  #expect(controller.isLauncherOpen)
}
