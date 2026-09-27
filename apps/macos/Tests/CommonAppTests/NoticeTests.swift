import AppKit
import Testing

@testable import CommonApp

@MainActor
private func notices(in window: NSWindow) -> [NoticeView] {
  window.contentView?.subviews.compactMap { $0 as? NoticeView } ?? []
}

@MainActor
@Test func aNoticeReplacesTheOneBeforeAndOutlivesAPageChange() throws {
  let controller = BrowserWindowController(url: URL(string: "about:blank")!)
  let window = try #require(controller.window)
  showNotice("first", in: window)
  showNotice("second", in: window)
  #expect(notices(in: window).map(\.text) == ["second"])

  controller.newPage(nil)
  #expect(notices(in: window).map(\.text) == ["second"])
  #expect(window.contentView?.subviews.last is NoticeView)
}

@MainActor
@Test func aNoticeGoesAwayUnlessANewerOneReplacedIt() async throws {
  let controller = BrowserWindowController(url: URL(string: "about:blank")!)
  let window = try #require(controller.window)

  // Poll rather than sleep a fixed time: other tests keep the main actor busy.
  showNotice("brief", in: window, for: .milliseconds(20))
  let deadline = ContinuousClock.now + uiTimeout
  while !notices(in: window).isEmpty, ContinuousClock.now < deadline {
    try await Task.sleep(for: .milliseconds(20))
  }
  #expect(notices(in: window).isEmpty)

  showNotice("brief", in: window, for: .milliseconds(20))
  showNotice("until replaced", in: window, for: nil)
  try await Task.sleep(for: .milliseconds(300))
  #expect(notices(in: window).map(\.text) == ["until replaced"])
}
