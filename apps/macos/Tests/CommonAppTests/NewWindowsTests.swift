import Foundation
import Testing
import WebKit

@testable import CommonApp

// The pages are real files, so each is its own document with its own navigation, as a site and
// its sign-in pop-up are. Script run by the app counts as a user gesture, which WebKit requires
// before a page may open another.

@MainActor
@Test func aTargetBlankLinkOpensAPageNextToItsOpener() async throws {
  let site = try Site([
    "opener.html": "<a href='popup.html' target=_blank>sign in</a>",
    "popup.html": "<title>popup</title>",
  ])
  let controller = try await site.open("opener.html")
  let opener = try #require(controller.currentWebView)
  // A page to the right, so the new page's place shows it went next to its opener, not last.
  controller.newPage(nil)
  controller.previousPage(nil)

  _ = try await opener.evaluateJavaScript("document.querySelector('a').click(); 0")
  let popup = try await eventually {
    controller.currentWebView.flatMap { $0 === opener ? nil : $0 }
  }
  #expect(controller.pageCount == 3)
  #expect(try await eventually { popup.title == "popup" ? true : nil })
  controller.previousPage(nil)
  #expect(controller.currentWebView === opener)
}

@MainActor
@Test func aPopUpReportsBackToItsOpenerAndClosesItself() async throws {
  // The shape of a sign-in pop-up: the site opens it, it posts its result to `window.opener`, and
  // closes itself.
  let site = try Site([
    "opener.html": """
    <script>
      addEventListener('message', event => document.title = 'got ' + event.data)
    </script>
    """,
    "popup.html": """
    <script>
      window.opener.postMessage('token', '*')
      window.close()
    </script>
    """,
  ])
  let controller = try await site.open("opener.html")
  let opener = try #require(controller.currentWebView)

  _ = try await opener.evaluateJavaScript("window.open('popup.html', 'signin', 'popup'); 0")
  #expect(try await eventually { opener.title == "got token" ? true : nil })
  #expect(try await eventually { controller.pageCount == 1 ? true : nil })
  #expect(controller.currentWebView === opener)
}

@MainActor
@Test func windowCloseClosesAPageOpenedByScriptAndShowsItsOpener() async throws {
  let site = try Site([
    "opener.html": "<title>opener</title>", "popup.html": "<title>popup</title>",
  ])
  let controller = try await site.open("opener.html")
  let opener = try #require(controller.currentWebView)
  // Pages to the right, where closing a page would otherwise go.
  controller.newPage(nil)
  controller.newPage(nil)
  controller.nextPage(nil)

  _ = try await opener.evaluateJavaScript("window.popup = window.open('popup.html'); 0")
  let popup = try await eventually {
    controller.currentWebView.flatMap { $0 === opener ? nil : $0 }
  }
  #expect(try await eventually { popup.title == "popup" ? true : nil })
  #expect(controller.pageCount == 4)

  _ = try await popup.evaluateJavaScript("window.close(); 0")
  #expect(try await eventually { controller.pageCount == 3 ? true : nil })
  #expect(controller.currentWebView === opener)
}

/// A few HTML files in a fresh directory, removed when the test lets go of it.
private final class Site {
  let directory: URL

  init(_ files: [String: String]) throws {
    directory = FileManager.default.temporaryDirectory
      .appendingPathComponent("common-browser-tests-\(UUID().uuidString)", isDirectory: true)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    for (name, html) in files {
      try html.write(to: directory.appendingPathComponent(name), atomically: true, encoding: .utf8)
    }
  }

  deinit {
    try? FileManager.default.removeItem(at: directory)
  }

  /// A window whose one page shows `name`, once it has loaded.
  @MainActor
  func open(_ name: String) async throws -> BrowserWindowController {
    let controller = BrowserWindowController(url: URL(string: "about:blank")!)
    let webView = try #require(controller.currentWebView)
    let file = directory.appendingPathComponent(name)
    webView.loadFileURL(file, allowingReadAccessTo: directory)
    _ = try await eventually {
      webView.url == file && !webView.isLoading ? true : nil
    }
    return controller
  }
}

private struct TimedOut: Error {}

/// Polls `value` until it is non-nil, for things that happen after script returns.
@MainActor
private func eventually<T>(_ value: @MainActor () async throws -> T?) async throws -> T {
  let deadline = ContinuousClock.now + uiTimeout
  while ContinuousClock.now < deadline {
    if let found = try await value() { return found }
    try await Task.sleep(for: .milliseconds(10))
  }
  throw TimedOut()
}
