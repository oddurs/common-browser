import Foundation
import Testing

@testable import CommonApp

@Test func opensTheFirstWebAddress() {
  let url = startURL(arguments: [
    "CommonBrowser", "--flag", "https://example.org", "https://two.example",
  ])
  #expect(url == URL(string: "https://example.org"))
}

@Test func ignoresArgumentsThatAreNotWebAddresses() {
  let url = startURL(arguments: ["CommonBrowser", "notes", "file:///etc/hosts"])
  #expect(url.absoluteString == "about:blank")
}
