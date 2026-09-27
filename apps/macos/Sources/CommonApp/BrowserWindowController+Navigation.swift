import AppKit
import WebKit

/// Back, forward, reload, stop and copy address act on the page on screen wherever focus is, and
/// their menu items are disabled when they cannot act.
extension BrowserWindowController: NSMenuItemValidation {
  public func navigateBack(_ sender: Any?) {
    currentWebView?.goBack()
  }

  public func navigateForward(_ sender: Any?) {
    currentWebView?.goForward()
  }

  public func reloadPage(_ sender: Any?) {
    currentWebView?.reload()
  }

  public func stopLoadingPage(_ sender: Any?) {
    currentWebView?.stopLoading()
  }

  public func copyAddress(_ sender: Any?) {
    copyAddress(to: .general)
  }

  func copyAddress(to pasteboard: NSPasteboard) {
    guard let address = currentWebView?.url?.absoluteString else { return }
    pasteboard.clearContents()
    pasteboard.setString(address, forType: .string)
  }

  public func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
    guard let action = menuItem.action else { return true }
    return Self.can(action, on: currentWebView)
  }

  /// Whether `action` can act on `page`. Actions other than navigation are always available.
  static func can(_ action: Selector, on page: WKWebView?) -> Bool {
    switch action {
    case #selector(BrowserActions.navigateBack(_:)): page?.canGoBack ?? false
    case #selector(BrowserActions.navigateForward(_:)): page?.canGoForward ?? false
    case #selector(BrowserActions.reloadPage(_:)), #selector(BrowserActions.copyAddress(_:)):
      page?.url != nil
    case #selector(BrowserActions.stopLoadingPage(_:)): page?.isLoading ?? false
    default: true
    }
  }
}
