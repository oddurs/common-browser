import CommonCore
import Foundation
import Testing
import WebKit

@testable import CommonApp

/// A downloads directory of its own for each test, never the user's.
@MainActor
private func freshDownloads() -> Downloads {
  Downloads(directory: FileManager.default.temporaryDirectory.appending(path: UUID().uuidString))
}

/// Downloads `path` from `server` and returns every event up to and including the last one.
/// `onEvent` sees each event as it happens, with the download, so a test can act mid-way.
@MainActor
private func download(
  _ path: String, from server: TestServer, into downloads: Downloads,
  onEvent: @escaping @MainActor (DownloadEvent, WKDownload) -> Void = { _, _ in }
) async -> [DownloadEvent] {
  let webView = WKWebView()
  var events: [DownloadEvent] = []
  return await withCheckedContinuation { continuation in
    downloads.report = { event, download in
      events.append(event)
      onEvent(event, download)
      if event.isFinal { continuation.resume(returning: events) }
    }
    webView.startDownload(using: URLRequest(url: server.url(path))) { $0.delegate = downloads }
  }
}

private func contents(of directory: URL) throws -> [String] {
  try FileManager.default.contentsOfDirectory(atPath: directory.path).sorted()
}

@Test func theSameNameTwiceIsNumbered() {
  #expect(uniqueDownloadName(suggested: "name.ext", taken: []) == "name.ext")
  #expect(uniqueDownloadName(suggested: "name.ext", taken: ["name.ext"]) == "name 2.ext")
}

@MainActor
@Test(.timeLimit(.minutes(1))) func downloadingTheSameFileTwiceKeepsBoth() async throws {
  let server = try await TestServer.start()
  server.replies["/name.ext"] = .init(body: Data("hello".utf8))
  let downloads = freshDownloads()

  let first = await download("/name.ext", from: server, into: downloads)
  let second = await download("/name.ext", from: server, into: downloads)

  #expect(first.first == .started(name: "name.ext"))
  #expect(first.last == .finished(downloads.directory.appending(path: "name.ext")))
  #expect(second.last == .finished(downloads.directory.appending(path: "name 2.ext")))
  #expect(try contents(of: downloads.directory) == ["name 2.ext", "name.ext"])
  let saved = try Data(contentsOf: downloads.directory.appending(path: "name 2.ext"))
  #expect(String(decoding: saved, as: UTF8.self) == "hello")
  #expect(downloads.latest == downloads.directory.appending(path: "name 2.ext"))
}

@MainActor
@Test(.timeLimit(.minutes(1))) func aFailedDownloadLeavesNoPartialFileAndSaysWhy() async throws {
  let server = try await TestServer.start()
  server.replies["/broken.zip"] = .init(body: Data(repeating: 1, count: 4096), ending: .drop)
  let downloads = freshDownloads()

  let events = await download("/broken.zip", from: server, into: downloads)

  // WebKit leaves the partial file in place when a download fails; Downloads must remove it.
  #expect(events.last == .failed(name: "broken.zip", reason: "The network connection was lost."))
  #expect(try contents(of: downloads.directory).isEmpty)
  #expect(downloads.latest == nil)
}

@MainActor
@Test(.timeLimit(.minutes(1))) func aCancelledDownloadLeavesNoPartialFileAndSaysWhy() async throws {
  let server = try await TestServer.start()
  // Half the body arrives, then the connection stalls, so the download is under way with a file
  // on disk when it is cancelled.
  server.replies["/big.dmg"] = .init(body: Data(repeating: 1, count: 4096), ending: .stall)
  let downloads = freshDownloads()
  var existedWhenCancelled = false

  let events = await download("/big.dmg", from: server, into: downloads) { event, download in
    guard case .progressed = event else { return }
    existedWhenCancelled = FileManager.default.fileExists(
      atPath: downloads.directory.appending(path: "big.dmg").path)
    downloads.cancel(download)
  }

  #expect(events.contains(.progressed(name: "big.dmg", percent: 50)))
  #expect(existedWhenCancelled)
  #expect(events.last == .cancelled(name: "big.dmg"))
  #expect(try contents(of: downloads.directory).isEmpty)
}

@MainActor
@Test(.timeLimit(.minutes(1))) func aDownloadThatCannotBeSavedSaysWhy() async throws {
  let server = try await TestServer.start()
  server.replies["/name.ext"] = .init(body: Data("hello".utf8))
  // A directory cannot be made inside a regular file.
  let file = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
  try Data().write(to: file)
  let downloads = Downloads(directory: file.appending(path: "Downloads"))

  let events = await download("/name.ext", from: server, into: downloads)

  guard case .failed(let name, let reason) = events.last else {
    Issue.record("the download did not fail: \(events)")
    return
  }
  #expect(name == "name.ext")
  #expect(!reason.isEmpty)
  #expect(events.count == 1)
}

@MainActor
@Test(.timeLimit(.minutes(1))) func aFinishedDownloadIsQuarantinedAsAWebDownload() async throws {
  let server = try await TestServer.start()
  server.replies["/tool.zip"] = .init(body: Data("zip".utf8))
  let downloads = freshDownloads()

  let events = await download("/tool.zip", from: server, into: downloads)

  guard case .finished(let file) = events.last else {
    Issue.record("the download did not finish: \(events)")
    return
  }
  let properties = try #require(
    try file.resourceValues(forKeys: [.quarantinePropertiesKey]).quarantineProperties)
  #expect(
    properties[kLSQuarantineTypeKey as String] as? String
      == kLSQuarantineTypeWebDownload as String)
  #expect(properties[kLSQuarantineAgentNameKey as String] as? String == "Common Browser")
  // Gatekeeper reads the extended attribute, "flags;time;agent;event", and checks files whose
  // flags have the download bit.
  var buffer = [UInt8](repeating: 0, count: 256)
  let length = getxattr(file.path, "com.apple.quarantine", &buffer, buffer.count, 0, 0)
  let attribute = String(decoding: buffer.prefix(max(length, 0)), as: UTF8.self)
  let flags = try #require(Int(attribute.prefix(4), radix: 16), "no quarantine: \(attribute)")
  #expect(flags & 0x1 != 0)
}

@Test func whatAPageCannotShowIsDownloaded() {
  let url = URL(string: "https://example.com/file")!
  func response(_ headers: [String: String]) -> URLResponse {
    HTTPURLResponse(url: url, statusCode: 200, httpVersion: "HTTP/1.1", headerFields: headers)!
  }
  #expect(PageDelegate.shouldDownload(response([:]), canShowMIMEType: false))
  #expect(!PageDelegate.shouldDownload(response([:]), canShowMIMEType: true))
  #expect(
    PageDelegate.shouldDownload(
      response(["Content-Disposition": "attachment; filename=\"a.pdf\""]), canShowMIMEType: true))
  #expect(
    PageDelegate.shouldDownload(
      response(["Content-Disposition": " Attachment"]), canShowMIMEType: true))
  #expect(
    !PageDelegate.shouldDownload(
      response(["Content-Disposition": "inline; filename=\"a.pdf\""]), canShowMIMEType: true))
}

@MainActor
@Test func theWindowCanShowTheLatestDownload() {
  let controller = BrowserWindowController(url: URL(string: "about:blank")!)
  #expect(controller.responds(to: #selector(BrowserActions.showLatestDownload(_:))))
}
