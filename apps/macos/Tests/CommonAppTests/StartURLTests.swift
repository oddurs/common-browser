import Foundation
import Testing

@testable import CommonApp

@Test func opensTheFirstWebAddress() {
  let url = startURL(
    arguments: [
      "CommonBrowser", "--flag", "https://example.org", "https://two.example",
    ], home: URL(string: "about:blank")!)
  #expect(url == URL(string: "https://example.org"))
}

@Test func withoutAWebAddressOpensHome() {
  let home = URL(string: "https://home.example")!
  let url = startURL(arguments: ["CommonBrowser", "notes", "file:///etc/hosts"], home: home)
  #expect(url == home)
}
