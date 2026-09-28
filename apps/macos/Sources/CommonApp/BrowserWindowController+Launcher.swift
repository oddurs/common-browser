import AppKit
import CommonCore
import WebKit

/// The launcher of one window: its panel, where focus goes back to, and the search engine.
@MainActor
final class LauncherState {
  let panel = LauncherPanel()
  /// What had focus before the launcher opened, so Esc can hand it back.
  weak var returnFocus: NSResponder?
  var searchEngine: String

  init(searchEngine: String) {
    self.searchEngine = searchEngine
  }
}

extension BrowserWindowController {
  /// ⌘L: the launcher over the page on screen.
  @objc public func openLocation(_ sender: Any?) {
    showLauncher()
  }

  var isLauncherOpen: Bool {
    launcher.panel.superview != nil && !launcher.panel.isHidden
  }

  func showLauncher() {
    let wasOpen = isLauncherOpen
    let panel = installLauncher()
    if !wasOpen {
      // While editing, the first responder is the field editor; the field itself is what to
      // return to.
      let responder = window?.firstResponder
      launcher.returnFocus = (responder as? NSTextView)?.delegate as? NSResponder ?? responder
    }
    panel.field.stringValue = ""
    refreshLauncher("")
    panel.isHidden = false
    window?.makeFirstResponder(panel.field)
  }

  func closeLauncher(restoringFocus: Bool) {
    guard isLauncherOpen else { return }
    launcher.panel.isHidden = true
    if restoringFocus, let responder = launcher.returnFocus {
      window?.makeFirstResponder(responder)
    }
    launcher.returnFocus = nil
  }

  private func installLauncher() -> LauncherPanel {
    let panel = launcher.panel
    guard panel.superview == nil, let content = window?.contentView else { return panel }
    panel.isHidden = true
    content.addSubview(panel)
    NSLayoutConstraint.activate([
      panel.centerXAnchor.constraint(equalTo: content.centerXAnchor),
      panel.topAnchor.constraint(equalTo: content.topAnchor, constant: 120),
    ])
    panel.onChange = { [weak self] text in self?.refreshLauncher(text) }
    panel.onGo = { [weak self] text in self?.go(to: text) }
    panel.onPick = { [weak self] id in self?.pickPage(id) }
    panel.onCancel = { [weak self] in self?.closeLauncher(restoringFocus: true) }
    return panel
  }

  private func refreshLauncher(_ text: String) {
    var rows: [LauncherRow] = []
    switch launcherDestination(input: text, engine: launcher.searchEngine) {
    case .address?:
      rows.append(.go("Go to \(text.trimmingCharacters(in: .whitespaces))"))
    case .search?:
      rows.append(.go("Search for \(text.trimmingCharacters(in: .whitespaces))"))
    case nil:
      break
    }
    let open = openPageSummaries()
    let sites = Dictionary(uniqueKeysWithValues: open.map { ($0.id, $0) })
    for id in launcherMatchingPages(query: text, pages: open) {
      guard let page = sites[id] else { continue }
      rows.append(.page(id: id, title: page.title, site: site(of: page.url)))
    }
    launcher.panel.show(rows)
  }

  /// Opens what the text names in the page on screen. The load starts before this returns, in the
  /// same event as Return.
  private func go(to text: String) {
    guard let destination = launcherDestination(input: text, engine: launcher.searchEngine)
    else { return }
    let address: String
    switch destination {
    case .address(let url), .search(let url): address = url
    }
    guard let url = URL(string: address), let page = currentWebView else { return }
    page.load(URLRequest(url: url))
    closeLauncher(restoringFocus: false)
    window?.makeFirstResponder(page)
  }

  private func pickPage(_ id: UInt64) {
    closeLauncher(restoringFocus: false)
    showPage(id)
  }

  private func openPageSummaries() -> [LauncherPage] {
    pageIDs.compactMap { id in
      webView(for: id).map {
        LauncherPage(id: id, title: $0.title ?? "", url: $0.url?.absoluteString ?? "")
      }
    }
  }

  private func site(of address: String) -> String {
    URL(string: address)?.host() ?? address
  }
}
