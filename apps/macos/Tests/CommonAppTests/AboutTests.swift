import AppKit
import Testing

@testable import CommonApp

@MainActor
@Test func aboutPanelShowsTheCoreVersion() throws {
  let version = try #require(aboutPanelOptions()[.applicationVersion] as? String)
  // Read through the Rust library, so this also proves the Swift build links it.
  #expect(version.wholeMatch(of: /\d+\.\d+\.\d+.*/) != nil)
}
