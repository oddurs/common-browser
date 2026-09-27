import AppKit
import CommonCore

/// What the banner says about a config with mistakes, or nil when there is nothing to say. It names
/// the first mistake with its line, because that is where the user has to look, and counts the rest.
public func configBannerText(for loaded: LoadedConfig) -> String? {
  if let unreadable = loaded.unreadable {
    return unreadable
  }
  guard let first = loaded.problems.first else { return nil }
  // The summary starts with "line:column: ", which the banner words for people instead.
  let message = first.summary.drop { $0 != " " }.dropFirst()
  let rest = loaded.problems.count - 1
  let more =
    switch rest {
    case 0: ""
    case 1: " · 1 more problem"
    default: " · \(rest) more problems"
    }
  return "common.toml, line \(first.line): \(message)\(more)"
}

/// Makes sure `common.toml` exists, with every setting in it commented out, and hands it to `open`.
@MainActor
public func openConfigFile(open: (URL) -> Void) throws {
  open(URL(fileURLWithPath: try ensureConfigFile()))
}

/// Opens `url` in the app registered for it, or in TextEdit when nothing claims `.toml` files.
@MainActor
public func openInEditor(_ url: URL) {
  let workspace = NSWorkspace.shared
  let editor =
    workspace.urlForApplication(toOpen: url)
    ?? URL(fileURLWithPath: "/System/Applications/TextEdit.app")
  workspace.open([url], withApplicationAt: editor, configuration: NSWorkspace.OpenConfiguration())
}
