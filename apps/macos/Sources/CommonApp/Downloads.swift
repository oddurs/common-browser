import AppKit
import CommonCore
import WebKit

/// What happened to a download, in the order the user hears about it.
enum DownloadEvent: Equatable {
  case started(name: String)
  case progressed(name: String, percent: Int)
  case finished(URL)
  case failed(name: String, reason: String)
  case cancelled(name: String)

  var isFinal: Bool {
    switch self {
    case .started, .progressed: false
    case .finished, .failed, .cancelled: true
    }
  }

  var message: String {
    switch self {
    case .started(let name): "Downloading \(name)…"
    case .progressed(let name, let percent): "Downloading \(name)… \(percent)%"
    case .finished(let file): "Downloaded \(file.lastPathComponent)"
    case .failed(let name, let reason): "Couldn't download \(name): \(reason)"
    case .cancelled(let name): "Cancelled downloading \(name)"
    }
  }
}

/// Saves every window's downloads into one directory. Downloads are app-wide, as in Safari: two
/// windows downloading the same file must not pick the same name, and Show Latest Download means
/// the latest of all.
@MainActor
public final class Downloads: NSObject, WKDownloadDelegate {
  public static let shared: Downloads = {
    let downloads = Downloads(directory: .downloadsDirectory)
    // A partial file left behind by quitting would pass for a finished download.
    _ = NotificationCenter.default.addObserver(
      forName: NSApplication.willTerminateNotification, object: nil, queue: .main
    ) { _ in
      MainActor.assumeIsolated { downloads.cancelAll() }
    }
    return downloads
  }()

  let directory: URL
  private struct InFlight {
    let file: URL
    var progress: NSKeyValueObservation?
    var percent = -1
  }

  /// The downloads under way. Their files may not exist yet, so a new download checks their names
  /// as well as the directory's.
  private var inFlight: [WKDownload: InFlight] = [:]
  /// Downloads already reported as failed before WebKit reports them cancelled.
  private var refused: Set<WKDownload> = []
  /// The file of the download that finished last.
  public private(set) var latest: URL?

  /// Tells the user about `event`. Tests replace it to follow a download.
  var report: @MainActor (DownloadEvent, WKDownload) -> Void = { event, download in
    // A download can start in a page that is not on screen, whose web view has no window.
    guard let window = download.webView?.window ?? NSApp.keyWindow else { return }
    showNotice(event.message, in: window, for: event.isFinal ? .seconds(4) : nil)
  }

  init(directory: URL) {
    self.directory = directory
  }

  public func download(
    _ download: WKDownload, decideDestinationUsing response: URLResponse,
    suggestedFilename: String, completionHandler: @escaping @MainActor @Sendable (URL?) -> Void
  ) {
    let destination: URL
    do {
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      let taken =
        try FileManager.default.contentsOfDirectory(atPath: directory.path)
        + inFlight.values.map(\.file.lastPathComponent)
      let name = uniqueDownloadName(suggested: suggestedFilename, taken: taken)
      destination = directory.appending(path: name, directoryHint: .notDirectory)
    } catch {
      refused.insert(download)
      report(.failed(name: suggestedFilename, reason: error.localizedDescription), download)
      completionHandler(nil)
      return
    }
    inFlight[download] = InFlight(file: destination, progress: observeProgress(of: download))
    report(.started(name: destination.lastPathComponent), download)
    completionHandler(destination)
  }

  public func downloadDidFinish(_ download: WKDownload) {
    guard let file = inFlight.removeValue(forKey: download)?.file else { return }
    do {
      try quarantine(file, from: download)
    } catch {
      // An unquarantined file would open without Gatekeeper's check, so it must not stay.
      let reason = "It could not be quarantined: \(error.localizedDescription)"
      report(.failed(name: file.lastPathComponent, reason: reason + remove(file)), download)
      return
    }
    latest = file
    report(.finished(file), download)
  }

  public func download(_ download: WKDownload, didFailWithError error: Error, resumeData: Data?) {
    if refused.remove(download) != nil { return }
    let file = inFlight.removeValue(forKey: download)?.file
    let name =
      file?.lastPathComponent ?? download.originalRequest?.url?.lastPathComponent ?? "file"
    let trouble = file.map(remove) ?? ""
    report(.failed(name: name, reason: error.localizedDescription + trouble), download)
  }

  /// Stops `download` and deletes what it saved so far. WebKit reports no failure for a download
  /// the app cancels, so this reports it.
  func cancel(_ download: WKDownload) {
    guard let file = inFlight.removeValue(forKey: download)?.file else { return }
    download.cancel(nil)
    let trouble = remove(file)
    let name = file.lastPathComponent
    report(
      trouble.isEmpty
        ? .cancelled(name: name) : .failed(name: name, reason: "Cancelled." + trouble), download)
  }

  func cancelAll() {
    inFlight.keys.forEach(cancel)
  }

  /// Deletes a partial or unsafe download. Returns nothing if that worked, else a sentence to
  /// add to the report, as the user must know a broken file is left behind.
  private func remove(_ file: URL) -> String {
    guard FileManager.default.fileExists(atPath: file.path) else { return "" }
    do {
      try FileManager.default.removeItem(at: file)
      return ""
    } catch {
      return " The partial file could not be removed: \(error.localizedDescription)"
    }
  }

  private func observeProgress(of download: WKDownload) -> NSKeyValueObservation {
    let id = ObjectIdentifier(download)
    return download.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
      // Without a Content-Length the total is unknown and the fraction means nothing.
      guard !progress.isIndeterminate else { return }
      let percent = Int(progress.fractionCompleted * 100)
      Task { @MainActor in self?.progressed(id, to: percent) }
    }
  }

  /// Reports whole percentages only, so a download arriving in many small pieces does not
  /// redraw the notice for each.
  private func progressed(_ id: ObjectIdentifier, to percent: Int) {
    guard let download = inFlight.keys.first(where: { ObjectIdentifier($0) == id }),
      let state = inFlight[download], percent > state.percent
    else { return }
    inFlight[download]?.percent = percent
    report(.progressed(name: state.file.lastPathComponent, percent: percent), download)
  }

  /// Marks `file` as downloaded from the web, as Safari does, so Gatekeeper checks it before it
  /// first opens. WebKit's own mark says only that a sandboxed process wrote the file, and the app
  /// has no `LSFileQuarantineEnabled` to make macOS mark it. macOS 26 does not keep the two URLs,
  /// as the quarantine records of other browsers show, but they are what the API asks for.
  private func quarantine(_ file: URL, from download: WKDownload) throws {
    var properties: [String: Any] = [
      kLSQuarantineAgentNameKey as String: "Common Browser",
      kLSQuarantineTypeKey as String: kLSQuarantineTypeWebDownload as String,
    ]
    if let source = download.originalRequest?.url {
      properties[kLSQuarantineDataURLKey as String] = source
    }
    if let page = download.webView?.url {
      properties[kLSQuarantineOriginURLKey as String] = page
    }
    var values = URLResourceValues()
    values.quarantineProperties = properties
    var file = file
    try file.setResourceValues(values)
  }
}

extension BrowserWindowController {
  public func showLatestDownload(_ sender: Any?) {
    guard let file = Downloads.shared.latest, FileManager.default.fileExists(atPath: file.path)
    else {
      NSSound.beep()
      return
    }
    NSWorkspace.shared.activateFileViewerSelecting([file])
  }
}
