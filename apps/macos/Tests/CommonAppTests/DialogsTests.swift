import AppKit
import Testing
import WebKit

@testable import CommonApp

// Each test runs script that opens a dialog, answers the real sheet the way a person would, and
// checks what the script got back. The script is started in a task because it does not finish
// until the sheet ends.

// Dialog tests open real windows and sheets; run one at a time so they never wait on each other.
@Suite(.serialized)
@MainActor
struct DialogTests {
  @MainActor
  @Test func alertShowsASheetWithTheMessageAndLetsThePageContinue() async throws {
    let (controller, window, webView) = try await page()
    defer { withExtendedLifetime(controller) {} }
    let result = run(webView, "alert('Saved'); 'continued'")
    let sheet = try await attachedSheet(of: window)
    #expect(texts(in: sheet).contains("Saved"))
    window.endSheet(sheet, returnCode: .alertFirstButtonReturn)
    #expect(try await result.value == "continued")
  }

  @MainActor
  @Test(arguments: [
    (NSApplication.ModalResponse.alertFirstButtonReturn, "true"),
    (.alertSecondButtonReturn, "false"),
  ])
  func confirmReturnsWhichButtonWasChosen(
    button: NSApplication.ModalResponse, expected: String
  ) async throws {
    let (controller, window, webView) = try await page()
    defer { withExtendedLifetime(controller) {} }
    let result = run(webView, "String(confirm('Delete?'))")
    let sheet = try await attachedSheet(of: window)
    #expect(texts(in: sheet).contains("Delete?"))
    window.endSheet(sheet, returnCode: button)
    #expect(try await result.value == expected)
  }

  @MainActor
  @Test func promptReturnsWhatWasTyped() async throws {
    let (controller, window, webView) = try await page()
    defer { withExtendedLifetime(controller) {} }
    let result = run(webView, "String(prompt('Name?', 'Ada'))")
    let sheet = try await attachedSheet(of: window)
    let field = try #require(editableField(in: sheet))
    #expect(field.stringValue == "Ada")
    field.stringValue = "Grace"
    window.endSheet(sheet, returnCode: .alertFirstButtonReturn)
    #expect(try await result.value == "Grace")
  }

  @MainActor
  @Test func cancellingAPromptReturnsNull() async throws {
    let (controller, window, webView) = try await page()
    defer { withExtendedLifetime(controller) {} }
    let result = run(webView, "String(prompt('Name?'))")
    let sheet = try await attachedSheet(of: window)
    window.endSheet(sheet, returnCode: .alertSecondButtonReturn)
    #expect(try await result.value == "null")
  }

  @MainActor
  @Test func fromTheSecondDialogOnAPageCanBeBlocked() async throws {
    let (controller, window, webView) = try await page()
    defer { withExtendedLifetime(controller) {} }

    let first = run(webView, "alert('one'); 'one done'")
    let firstSheet = try await attachedSheet(of: window)
    #expect(blockButton(in: firstSheet) == nil)
    window.endSheet(firstSheet, returnCode: .alertFirstButtonReturn)
    #expect(try await first.value == "one done")

    let second = run(webView, "alert('two'); 'two done'")
    let secondSheet = try await attachedSheet(of: window)
    let block = try #require(blockButton(in: secondSheet))
    block.state = .on
    window.endSheet(secondSheet, returnCode: .alertFirstButtonReturn)
    #expect(try await second.value == "two done")

    // Blocked dialogs answer at once, as if dismissed, without a sheet.
    let blocked = try await webView.evaluateJavaScript(
      "alert('three'); [confirm('four'), prompt('five')].join()")
    #expect(blocked as? String == "false,")
    #expect(window.attachedSheet == nil)
  }

  @MainActor
  @Test func closingThePageAnswersItsDialog() async throws {
    let controller = BrowserWindowController(url: URL(string: "about:blank")!)
    let window = try #require(controller.window)
    let webView = try #require(controller.currentWebView)
    try await load(webView, html: "<p>page</p>")
    let result = run(webView, "String(confirm('Leave?'))")
    _ = try await attachedSheet(of: window)
    controller.closePage(nil)
    #expect(try await result.value == "false")
    #expect(window.attachedSheet == nil)
  }

  @MainActor
  @Test func closingTheWindowAnswersItsDialog() async throws {
    let (controller, window, webView) = try await page()
    defer { withExtendedLifetime(controller) {} }
    let result = run(webView, "String(prompt('Name?'))")
    _ = try await attachedSheet(of: window)
    window.close()
    #expect(try await result.value == "null")
  }

  @MainActor
  @Test func aPageOffScreenIsAnsweredWithoutASheet() async throws {
    let delegate = PageDelegate()
    let webView = makePageWebView(delegate: delegate)
    try await load(webView, html: "<p>hidden</p>")
    let result = try await webView.evaluateJavaScript(
      "alert('hi'); String(confirm('ok?')) + ' ' + prompt('name?')")
    #expect(result as? String == "false null")
    withExtendedLifetime(delegate) {}
  }

  // A file input's panel is only checked for how it is set up. Ending an open panel in the test
  // process ends the process, with status 0, so a test that shows one cannot pass or fail.
  @MainActor
  @Test(arguments: [(false, false), (true, false), (false, true)])
  func theFilePanelMatchesTheInput(multiple: Bool, directories: Bool) {
    let panel = makeOpenPanel(allowsMultipleSelection: multiple, allowsDirectories: directories)
    #expect(panel.allowsMultipleSelection == multiple)
    #expect(panel.canChooseDirectories == directories)
    #expect(panel.canChooseFiles == !directories)
  }

  /// A page in a window, loaded with `html`. The controller comes back too because it owns the
  /// page's delegate, which the web view holds only weakly.
}

@MainActor
private func page(_ html: String = "<p>page</p>") async throws -> (
  BrowserWindowController, NSWindow, WKWebView
) {
  let controller = BrowserWindowController(url: URL(string: "about:blank")!)
  let window = try #require(controller.window)
  let webView = try #require(controller.currentWebView)
  try await load(webView, html: html)
  return (controller, window, webView)
}

/// Starts `script`, which returns a string once its dialogs are answered.
@MainActor
private func run(_ webView: WKWebView, _ script: String) -> Task<String?, Error> {
  Task { try await webView.evaluateJavaScript(script) as? String }
}

@MainActor
private func attachedSheet(of window: NSWindow) async throws -> NSWindow {
  let deadline = ContinuousClock.now + uiTimeout
  while ContinuousClock.now < deadline {
    if let sheet = window.attachedSheet { return sheet }
    try await Task.sleep(for: .milliseconds(10))
  }
  throw NoSheet()
}

private struct NoSheet: Error {}

@MainActor
private func views(in sheet: NSWindow) -> [NSView] {
  var found: [NSView] = []
  var queue = sheet.contentView.map { [$0] } ?? []
  while let view = queue.popLast() {
    found.append(view)
    queue.append(contentsOf: view.subviews)
  }
  return found
}

@MainActor
private func texts(in sheet: NSWindow) -> [String] {
  views(in: sheet).compactMap { ($0 as? NSTextField)?.stringValue }
}

@MainActor
private func editableField(in sheet: NSWindow) -> NSTextField? {
  views(in: sheet).compactMap { $0 as? NSTextField }.first { $0.isEditable }
}

@MainActor
private func blockButton(in sheet: NSWindow) -> NSButton? {
  views(in: sheet).compactMap { $0 as? NSButton }.first {
    $0.title.hasPrefix("Block") && !$0.isHiddenOrHasHiddenAncestor
  }
}
