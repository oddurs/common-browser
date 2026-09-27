import AppKit
import Testing
import WebKit

@testable import CommonApp

/// Whether the menu bar's item for `id` is enabled for `controller`, as AppKit asks when the menu
/// opens or its shortcut is pressed.
@MainActor
private func isEnabled(_ id: String, in controller: BrowserWindowController) throws -> Bool {
  let items = menuBar().items.flatMap { $0.submenu?.items ?? [] }
  let item = try #require(items.first { $0.identifier?.rawValue == id })
  return controller.validateMenuItem(item)
}

/// Visits a page titled `title`. Unlike `load(_:html:)`, this adds to the back-forward list.
@MainActor
private func visit(_ page: WKWebView, titled title: String) async throws {
  try await navigate(page) { $0.load(URLRequest(url: address(of: title))) }
}

private func address(of title: String) -> URL {
  URL(string: "data:text/html,<title>\(title)</title>")!
}

/// A window whose page has visited "one" then "two".
@MainActor
private func windowWithHistory() async throws -> (BrowserWindowController, WKWebView) {
  let controller = BrowserWindowController(url: URL(string: "about:blank")!)
  let page = try #require(controller.currentWebView)
  try await visit(page, titled: "one")
  try await visit(page, titled: "two")
  return (controller, page)
}

/// Waits for the back-forward list to move to `title`. The list moves as soon as the page acts;
/// the page itself may take long to restore, as WebKit defers work for pages in hidden windows.
@MainActor
private func waitForHistory(at title: String, on page: WKWebView) async throws {
  let deadline = ContinuousClock.now + .seconds(20)
  while page.backForwardList.currentItem?.url != address(of: title),
    ContinuousClock.now < deadline
  {
    try await Task.sleep(for: .milliseconds(20))
  }
  #expect(page.backForwardList.currentItem?.url == address(of: title))
}

@MainActor
@Test func backAndForwardAreDisabledWithoutHistory() throws {
  let controller = BrowserWindowController(url: URL(string: "about:blank")!)
  #expect(try !isEnabled("back", in: controller))
  #expect(try !isEnabled("forward", in: controller))
}

@MainActor
@Test(.timeLimit(.minutes(1))) func backWorksWhenFocusIsOffThePage() async throws {
  let (controller, page) = try await windowWithHistory()
  let window = try #require(controller.window)
  #expect(try isEnabled("back", in: controller))
  #expect(try !isEnabled("forward", in: controller))

  // The action travels up from the window to its controller.
  window.makeFirstResponder(nil)
  #expect(window.tryToPerform(#selector(BrowserActions.navigateBack(_:)), with: nil))
  try await waitForHistory(at: "one", on: page)
  #expect(try isEnabled("forward", in: controller))
}

@MainActor
@Test(.timeLimit(.minutes(1))) func backWorksWhenThePageHasFocus() async throws {
  let (controller, page) = try await windowWithHistory()
  let window = try #require(controller.window)

  // WebKit does not claim the action, so it passes the page on its way to the controller.
  window.makeFirstResponder(page)
  #expect(page.tryToPerform(#selector(BrowserActions.navigateBack(_:)), with: nil))
  try await waitForHistory(at: "one", on: page)
}

/// Answers every `stall:` request with nothing, so the page stays loading.
@MainActor
private final class Staller: NSObject, WKURLSchemeHandler {
  var requested = false

  func webView(_ webView: WKWebView, start task: any WKURLSchemeTask) {
    requested = true
  }

  func webView(_ webView: WKWebView, stop task: any WKURLSchemeTask) {}
}

@MainActor
@Test(.timeLimit(.minutes(1))) func stopIsEnabledOnlyWhileAPageLoads() async throws {
  let staller = Staller()
  let configuration = WKWebViewConfiguration()
  configuration.setURLSchemeHandler(staller, forURLScheme: "stall")
  let page = WKWebView(frame: .zero, configuration: configuration)
  let stop = #selector(BrowserActions.stopLoadingPage(_:))
  #expect(!BrowserWindowController.can(stop, on: page))

  page.load(URLRequest(url: URL(string: "stall://page")!))
  // Stopping before the request goes out is a race WebKit can lose, leaving the page loading.
  while !staller.requested { try await Task.sleep(for: .milliseconds(10)) }
  #expect(BrowserWindowController.can(stop, on: page))

  page.stopLoading()
  while page.isLoading { try await Task.sleep(for: .milliseconds(10)) }
  #expect(!BrowserWindowController.can(stop, on: page))
}

@MainActor
@Test(.timeLimit(.minutes(1))) func copyAddressPutsThePagesURLOnThePasteboard() async throws {
  let controller = BrowserWindowController(url: URL(string: "about:blank")!)
  let page = try #require(controller.currentWebView)
  try await navigate(page) { $0.load(URLRequest(url: URL(string: "data:text/html,<p>hi")!)) }
  #expect(try isEnabled("copy-address", in: controller))
  #expect(try isEnabled("reload", in: controller))

  // A private pasteboard, so running the tests leaves the user's clipboard alone.
  let pasteboard = NSPasteboard.withUniqueName()
  defer { pasteboard.releaseGlobally() }
  pasteboard.setString("before", forType: .string)
  controller.copyAddress(to: pasteboard)
  #expect(pasteboard.string(forType: .string) == "data:text/html,%3Cp%3Ehi")
}

@MainActor
@Test func aPageWithoutAnAddressHasNothingToCopyOrReload() {
  let blank = WKWebView()
  #expect(!BrowserWindowController.can(#selector(BrowserActions.copyAddress(_:)), on: blank))
  #expect(!BrowserWindowController.can(#selector(BrowserActions.reloadPage(_:)), on: blank))
  #expect(!BrowserWindowController.can(#selector(BrowserActions.navigateBack(_:)), on: nil))
  #expect(BrowserWindowController.can(#selector(BrowserActions.newPage(_:)), on: nil))
}

@MainActor
@Test func pagesSwipeBackAndForward() {
  #expect(makePageWebView(delegate: PageDelegate()).allowsBackForwardNavigationGestures)
}
