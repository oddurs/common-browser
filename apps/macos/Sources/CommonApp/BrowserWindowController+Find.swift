import AppKit
import WebKit

/// Find in page for one window: the bar, the page it last searched, and the searches in flight.
@MainActor
final class FindState {
  let bar = FindBar()
  /// The page whose matches are highlighted, so closing the bar can clear them even after another
  /// page has taken its place.
  weak var page: WKWebView?
  /// Work on pages runs one job after another. A search that a newer job has overtaken is skipped:
  /// typing "fox" quickly should not search for "f" and "fo" as well. Clearing highlights always
  /// runs, or a page left behind would keep them.
  private var generation = 0
  private var last: Task<Void, Never>?

  func search(_ search: @escaping @MainActor () async -> FindStatus) {
    generation += 1
    let mine = generation
    enqueue { [weak self] in
      guard mine == self?.generation else { return }
      let status = await search()
      if mine == self?.generation {
        self?.bar.status = status
      }
    }
  }

  func clear(_ page: WKWebView) {
    generation += 1
    enqueue { await clearFindHighlights(page) }
  }

  private func enqueue(_ job: @escaping @MainActor () async -> Void) {
    let previous = last
    last = Task { @MainActor in
      await previous?.value
      await job()
    }
  }

  /// Waits for every queued search, for tests.
  func settle() async {
    await last?.value
  }
}

extension BrowserWindowController {
  @objc public func showFind(_ sender: Any?) {
    let bar = installFindBar()
    bar.isHidden = false
    window?.makeFirstResponder(bar.field)
  }

  @objc public func findNextMatch(_ sender: Any?) {
    findStep(backwards: false)
  }

  @objc public func findPreviousMatch(_ sender: Any?) {
    findStep(backwards: true)
  }

  /// Hides the bar and clears the highlights. The current match stays selected, so the page can
  /// copy it.
  func closeFind() {
    guard !find.bar.isHidden else { return }
    find.bar.isHidden = true
    find.bar.status = .idle
    if let page = find.page {
      find.clear(page)
    }
  }

  /// ⌘G with nothing to find opens the bar instead, as Safari does.
  private func findStep(backwards: Bool) {
    let bar = installFindBar()
    guard !bar.query.isEmpty else { return showFind(nil) }
    bar.isHidden = false
    search(bar.query, backwards: backwards)
  }

  private func search(_ query: String, backwards: Bool = false) {
    guard let page = currentWebView else { return }
    find.page = page
    find.search { await findInPage(page, query, backwards: backwards) }
  }

  private func installFindBar() -> FindBar {
    let bar = find.bar
    guard bar.superview == nil, let content = window?.contentView else { return bar }
    bar.onChange = { [weak self] query in self?.search(query) }
    bar.onStep = { [weak self] backwards in self?.findStep(backwards: backwards) }
    bar.onClose = { [weak self] in
      guard let self else { return }
      self.closeFind()
      if let page = self.currentWebView {
        self.window?.makeFirstResponder(page)
      }
    }
    bar.translatesAutoresizingMaskIntoConstraints = false
    content.addSubview(bar)
    NSLayoutConstraint.activate([
      bar.centerXAnchor.constraint(equalTo: content.centerXAnchor),
      // The safe area starts below the transparent title bar, clear of the window buttons.
      bar.topAnchor.constraint(equalTo: content.safeAreaLayoutGuide.topAnchor, constant: 8),
      bar.widthAnchor.constraint(equalToConstant: 300),
      bar.heightAnchor.constraint(equalToConstant: FindBar.height),
    ])
    return bar
  }
}
