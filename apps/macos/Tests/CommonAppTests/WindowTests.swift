import AppKit
import Testing

@testable import CommonApp

private let laptop = NSRect(x: 0, y: 0, width: 1440, height: 875)
private let monitor = NSRect(x: 1440, y: 0, width: 2560, height: 1415)

@Test func aFrameOnAScreenIsKept() {
  let frame = NSRect(x: 1600, y: 200, width: 1200, height: 800)
  #expect(fitted(frame, into: [laptop, monitor]) == frame)
}

@Test func aFrameLeftOnAMissingScreenMovesOntoTheFirstOne() {
  let frame = NSRect(x: 1600, y: 200, width: 1200, height: 800)
  let moved = fitted(frame, into: [laptop])
  #expect(laptop.contains(moved))
  #expect(moved.size == frame.size)
}

@Test func aFrameLargerThanTheScreenShrinksToFit() {
  let frame = NSRect(x: 5000, y: 0, width: 2500, height: 1400)
  #expect(fitted(frame, into: [laptop]) == laptop)
}

@Test func aFrameWhoseTitleBarIsOffScreenIsMoved() {
  // Only the bottom of the window shows: its title bar is above the top of the screen.
  let frame = NSRect(x: 100, y: 800, width: 1000, height: 700)
  #expect(fitted(frame, into: [laptop]) != frame)
}

@MainActor
@Test func pagesFillTheWholeWindowUnderTheTitleBar() throws {
  let controller = BrowserWindowController(url: URL(string: "about:blank")!)
  let window = try #require(controller.window)
  #expect(window.styleMask.contains(.fullSizeContentView))
  #expect(window.titlebarAppearsTransparent)
  #expect(window.contentView?.frame.size == window.frame.size)
  #expect(window.collectionBehavior.contains(.fullScreenPrimary))
}
