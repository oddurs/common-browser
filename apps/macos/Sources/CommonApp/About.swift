import AppKit
import CommonCore

/// The About panel reports the core's version, not the Swift bundle's, because the core is what
/// every platform shares and what a bug report needs to name.
@MainActor
public func aboutPanelOptions() -> [NSApplication.AboutPanelOptionKey: Any] {
  [
    .applicationName: "Common Browser",
    .applicationVersion: coreVersion(),
  ]
}
