import AppKit
import WebKit

/// JavaScript's `alert`, `confirm` and `prompt`, and file inputs, as sheets on the page's window.
///
/// WebKit blocks the page's script until its completion handler runs, and requires that it runs
/// exactly once. These are the async forms of the delegate methods, so WebKit's bridge calls the
/// handler when each returns; every path below returns, including when the window closes or the
/// page leaves it while a sheet is up.
extension PageDelegate {
  public func webView(
    _ webView: WKWebView, runJavaScriptAlertPanelWithMessage message: String,
    initiatedByFrame frame: WKFrameInfo
  ) async {
    _ = await runDialog(in: webView, from: frame, message: message, buttons: ["OK"])
  }

  public func webView(
    _ webView: WKWebView, runJavaScriptConfirmPanelWithMessage message: String,
    initiatedByFrame frame: WKFrameInfo
  ) async -> Bool {
    let response = await runDialog(
      in: webView, from: frame, message: message, buttons: ["OK", "Cancel"])
    return response == .alertFirstButtonReturn
  }

  public func webView(
    _ webView: WKWebView, runJavaScriptTextInputPanelWithPrompt prompt: String,
    defaultText: String?, initiatedByFrame frame: WKFrameInfo
  ) async -> String? {
    let field = NSTextField(string: defaultText ?? "")
    field.frame = NSRect(x: 0, y: 0, width: 300, height: 22)
    let response = await runDialog(
      in: webView, from: frame, message: prompt, buttons: ["OK", "Cancel"], field: field)
    return response == .alertFirstButtonReturn ? field.stringValue : nil
  }

  public func webView(
    _ webView: WKWebView, runOpenPanelWith parameters: WKOpenPanelParameters,
    initiatedByFrame frame: WKFrameInfo
  ) async -> [URL]? {
    guard let window = webView.window else { return nil }
    let panel = makeOpenPanel(
      allowsMultipleSelection: parameters.allowsMultipleSelection,
      allowsDirectories: parameters.allowsDirectories)
    // An open panel is ended with its own cancel action: it runs partly out of process, and
    // cancelling lets it tidy up that side too.
    let response = await runSheet(
      on: window, for: webView,
      begin: { await panel.beginSheetModal(for: window) },
      cancel: { panel.cancel(nil) })
    return response == .OK ? panel.urls : nil
  }

  /// Shows one dialog and returns which button ended it, or `.cancel` if none did: the page was
  /// not on screen, it has been blocked from showing dialogs, or the sheet was dismissed for it.
  private func runDialog(
    in webView: WKWebView, from frame: WKFrameInfo, message: String, buttons: [String],
    field: NSTextField? = nil
  ) async -> NSApplication.ModalResponse {
    // A page that is not on screen has no window to put a sheet on. Answering as if dismissed
    // keeps its script running rather than parked behind a dialog nobody can see.
    guard let window = webView.window else { return .cancel }
    let history = Self.dialogHistory(of: webView, origin: frame.securityOrigin)
    guard !history.blocked else { return .cancel }
    history.shown += 1

    let alert = NSAlert()
    let host = frame.securityOrigin.host
    alert.messageText = host.isEmpty ? "This page says" : "\(host) says"
    alert.informativeText = message
    for title in buttons {
      alert.addButton(withTitle: title)
    }
    if let field {
      alert.accessoryView = field
      alert.window.initialFirstResponder = field
    }
    // A page that opens dialogs in a loop would otherwise hold the window hostage, so from the
    // second one on the sheet offers a way out.
    if history.shown >= 2 {
      alert.showsSuppressionButton = true
      alert.suppressionButton?.title = "Block further dialogs from this page"
    }

    let response = await runSheet(
      on: window, for: webView,
      begin: { await alert.beginSheetModal(for: window) },
      cancel: { [weak window, weak alert] in
        guard let window, let sheet = alert?.window, window.sheets.contains(sheet) else { return }
        window.endSheet(sheet, returnCode: .cancel)
      })
    if alert.suppressionButton?.state == .on {
      history.blocked = true
    }
    return response
  }

  /// Runs `begin`, which shows a sheet on `window` and waits for it to end, and calls `cancel` to
  /// end it early if the window closes or the page leaves it. Ending the sheet is the one way out,
  /// so the answer to WebKit is given once, whichever way the sheet goes.
  private func runSheet(
    on window: NSWindow, for webView: WKWebView,
    begin: () async -> NSApplication.ModalResponse,
    cancel: @escaping @MainActor @Sendable () -> Void
  ) async -> NSApplication.ModalResponse {
    let watcher = WindowLeaveWatcher()
    watcher.onLeave = cancel
    webView.addSubview(watcher)
    let closing = NotificationCenter.default.addObserver(
      forName: NSWindow.willCloseNotification, object: window, queue: .main
    ) { _ in MainActor.assumeIsolated { cancel() } }
    defer {
      NotificationCenter.default.removeObserver(closing)
      // Removing the watcher is itself leaving the window, which must not cancel a later sheet.
      watcher.onLeave = nil
      watcher.removeFromSuperview()
    }
    return await begin()
  }

  /// Dialogs are counted per page and per origin: navigating to another site starts afresh, so a
  /// block on one site does not silence the next.
  private static func dialogHistory(of webView: WKWebView, origin: WKSecurityOrigin)
    -> DialogHistory
  {
    let key = "\(origin.protocol)://\(origin.host):\(origin.port)"
    if let history = dialogHistories.object(forKey: webView), history.origin == key {
      return history
    }
    let history = DialogHistory(origin: key)
    dialogHistories.setObject(history, forKey: webView)
    return history
  }

  // Weak keys, so a closed page's history goes with it.
  private static let dialogHistories = NSMapTable<WKWebView, DialogHistory>.weakToStrongObjects()
}

@MainActor
private final class DialogHistory {
  let origin: String
  var shown = 0
  var blocked = false

  init(origin: String) {
    self.origin = origin
  }
}

/// An open panel set up for a file input: several files if it has `multiple`, and for a directory
/// input (`webkitdirectory`) a folder, whose files WebKit then lists.
@MainActor
func makeOpenPanel(allowsMultipleSelection: Bool, allowsDirectories: Bool) -> NSOpenPanel {
  let panel = NSOpenPanel()
  panel.allowsMultipleSelection = allowsMultipleSelection
  panel.canChooseDirectories = allowsDirectories
  panel.canChooseFiles = !allowsDirectories
  return panel
}

/// A hidden subview of the page that learns when the page leaves its window, which AppKit tells
/// every view in a subtree when the subtree is removed.
@MainActor
private final class WindowLeaveWatcher: NSView {
  var onLeave: (() -> Void)?

  init() {
    super.init(frame: .zero)
    isHidden = true
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("WindowLeaveWatcher is created in code")
  }

  override func viewDidMoveToWindow() {
    if window == nil { onLeave?() }
  }
}
