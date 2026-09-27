import AppKit

/// The browser's own actions. Menu items send these up the responder chain, so a feature takes
/// effect by implementing its method on the window controller or app delegate; until then AppKit
/// shows the item disabled. The protocol exists so each selector is declared exactly once.
@MainActor @objc public protocol BrowserActions {
  @objc optional func showAbout(_ sender: Any?)
  @objc optional func openConfig(_ sender: Any?)
  @objc optional func newPage(_ sender: Any?)
  @objc optional func openLocation(_ sender: Any?)
  @objc optional func closePage(_ sender: Any?)
  @objc optional func showLatestDownload(_ sender: Any?)
  @objc optional func copyAddress(_ sender: Any?)
  @objc optional func showFind(_ sender: Any?)
  @objc optional func findNextMatch(_ sender: Any?)
  @objc optional func findPreviousMatch(_ sender: Any?)
  @objc optional func navigateBack(_ sender: Any?)
  @objc optional func navigateForward(_ sender: Any?)
  @objc optional func reloadPage(_ sender: Any?)
  @objc optional func stopLoadingPage(_ sender: Any?)
  @objc optional func previousPage(_ sender: Any?)
  @objc optional func nextPage(_ sender: Any?)
}

/// The top-level menus, in menu bar order.
public enum MenuName: String, CaseIterable, Sendable {
  case app = "Common Browser"
  case file = "File"
  case edit = "Edit"
  case view = "View"
  case history = "History"
  case window = "Window"
}

/// Modifier keys, kept separate from `NSEvent.ModifierFlags` so the table is plain data.
public struct Modifiers: OptionSet, Hashable, Sendable {
  public let rawValue: Int
  public init(rawValue: Int) { self.rawValue = rawValue }

  public static let control = Modifiers(rawValue: 1 << 0)
  public static let option = Modifiers(rawValue: 1 << 1)
  public static let shift = Modifiers(rawValue: 1 << 2)
  public static let command = Modifiers(rawValue: 1 << 3)
}

/// A key plus modifiers, as a menu item's key equivalent. `key` is a lowercase character, or one
/// of AppKit's function-key characters for the arrows; shift is always explicit.
public struct Shortcut: Hashable, Sendable {
  public let key: String
  public let modifiers: Modifiers

  public init(_ key: String, _ modifiers: Modifiers = .command) {
    self.key = key
    self.modifiers = modifiers
  }

  static let leftArrow = String(UnicodeScalar(NSLeftArrowFunctionKey)!)
  static let rightArrow = String(UnicodeScalar(NSRightArrowFunctionKey)!)

  /// How macOS writes it, such as ⇧⌘C: modifiers in the system's order, then the key.
  public var symbols: String {
    let order: [(Modifiers, String)] = [
      (.control, "⌃"), (.option, "⌥"), (.shift, "⇧"), (.command, "⌘"),
    ]
    let prefix = order.filter { modifiers.contains($0.0) }.map(\.1).joined()
    let name: String =
      switch key {
      case Shortcut.leftArrow: "←"
      case Shortcut.rightArrow: "→"
      default: key.uppercased()
      }
    return prefix + name
  }

  var modifierFlags: NSEvent.ModifierFlags {
    var flags: NSEvent.ModifierFlags = []
    if modifiers.contains(.control) { flags.insert(.control) }
    if modifiers.contains(.option) { flags.insert(.option) }
    if modifiers.contains(.shift) { flags.insert(.shift) }
    if modifiers.contains(.command) { flags.insert(.command) }
    return flags
  }
}

/// One entry in the menu bar. Commands in the same menu with different `group`s are separated by a
/// divider.
public struct Command: Sendable {
  public let id: String
  public let title: String
  public let menu: MenuName
  public let group: Int
  public let shortcut: Shortcut?
  public let action: Selector

  public init(
    _ id: String, _ title: String, in menu: MenuName, group: Int = 0, shortcut: Shortcut? = nil,
    action: Selector
  ) {
    self.id = id
    self.title = title
    self.menu = menu
    self.group = group
    self.shortcut = shortcut
    self.action = action
  }
}

extension Command {
  /// Every command in the browser. This table is the keymap: nothing binds a key anywhere else.
  public static let all: [Command] = [
    Command(
      "about", "About Common Browser", in: .app,
      action: #selector(BrowserActions.showAbout(_:))),
    Command(
      "settings", "Settings…", in: .app, group: 1, shortcut: Shortcut(","),
      action: #selector(BrowserActions.openConfig(_:))),
    Command(
      "hide", "Hide Common Browser", in: .app, group: 2, shortcut: Shortcut("h"),
      action: #selector(NSApplication.hide(_:))),
    Command(
      "hide-others", "Hide Others", in: .app, group: 2,
      shortcut: Shortcut("h", [.option, .command]),
      action: #selector(NSApplication.hideOtherApplications(_:))),
    Command(
      "show-all", "Show All", in: .app, group: 2,
      action: #selector(NSApplication.unhideAllApplications(_:))),
    Command(
      "quit", "Quit Common Browser", in: .app, group: 3, shortcut: Shortcut("q"),
      action: #selector(NSApplication.terminate(_:))),

    Command(
      "new-page", "New Page", in: .file, shortcut: Shortcut("t"),
      action: #selector(BrowserActions.newPage(_:))),
    Command(
      "open-location", "Open Location…", in: .file, shortcut: Shortcut("l"),
      action: #selector(BrowserActions.openLocation(_:))),
    Command(
      "close-page", "Close Page", in: .file, group: 1, shortcut: Shortcut("w"),
      action: #selector(BrowserActions.closePage(_:))),
    Command(
      "show-latest-download", "Show Latest Download", in: .file, group: 2,
      shortcut: Shortcut("l", [.option, .command]),
      action: #selector(BrowserActions.showLatestDownload(_:))),

    // The standard editing actions: without them text fields and pages lose copy and paste.
    Command("undo", "Undo", in: .edit, shortcut: Shortcut("z"), action: Selector(("undo:"))),
    Command(
      "redo", "Redo", in: .edit, shortcut: Shortcut("z", [.shift, .command]),
      action: Selector(("redo:"))),
    Command(
      "cut", "Cut", in: .edit, group: 1, shortcut: Shortcut("x"),
      action: #selector(NSText.cut(_:))),
    Command(
      "copy", "Copy", in: .edit, group: 1, shortcut: Shortcut("c"),
      action: #selector(NSText.copy(_:))),
    Command(
      "paste", "Paste", in: .edit, group: 1, shortcut: Shortcut("v"),
      action: #selector(NSText.paste(_:))),
    Command(
      "select-all", "Select All", in: .edit, group: 1, shortcut: Shortcut("a"),
      action: #selector(NSText.selectAll(_:))),
    Command(
      "copy-address", "Copy Address", in: .edit, group: 2,
      shortcut: Shortcut("c", [.shift, .command]),
      action: #selector(BrowserActions.copyAddress(_:))),
    Command(
      "find", "Find…", in: .edit, group: 3, shortcut: Shortcut("f"),
      action: #selector(BrowserActions.showFind(_:))),
    Command(
      "find-next", "Find Next", in: .edit, group: 3, shortcut: Shortcut("g"),
      action: #selector(BrowserActions.findNextMatch(_:))),
    Command(
      "find-previous", "Find Previous", in: .edit, group: 3,
      shortcut: Shortcut("g", [.shift, .command]),
      action: #selector(BrowserActions.findPreviousMatch(_:))),

    // The window, not WKWebView's own `reload:` and friends, handles navigation: those work only
    // while the page has focus and would leave the items enabled when they cannot act.
    Command(
      "reload", "Reload Page", in: .view, shortcut: Shortcut("r"),
      action: #selector(BrowserActions.reloadPage(_:))),
    Command(
      "stop", "Stop Loading", in: .view, shortcut: Shortcut("."),
      action: #selector(BrowserActions.stopLoadingPage(_:))),
    Command(
      "full-screen", "Enter Full Screen", in: .view, group: 1,
      shortcut: Shortcut("f", [.control, .command]),
      action: #selector(NSWindow.toggleFullScreen(_:))),

    Command(
      "back", "Back", in: .history, shortcut: Shortcut("["),
      action: #selector(BrowserActions.navigateBack(_:))),
    Command(
      "forward", "Forward", in: .history, shortcut: Shortcut("]"),
      action: #selector(BrowserActions.navigateForward(_:))),

    Command(
      "minimize", "Minimize", in: .window, shortcut: Shortcut("m"),
      action: #selector(NSWindow.performMiniaturize(_:))),
    Command("zoom", "Zoom", in: .window, action: #selector(NSWindow.performZoom(_:))),
    Command(
      "previous-page", "Previous Page", in: .window, group: 1,
      shortcut: Shortcut(Shortcut.leftArrow, [.option, .command]),
      action: #selector(BrowserActions.previousPage(_:))),
    Command(
      "next-page", "Next Page", in: .window, group: 1,
      shortcut: Shortcut(Shortcut.rightArrow, [.option, .command]),
      action: #selector(BrowserActions.nextPage(_:))),
    Command(
      "bring-all-to-front", "Bring All to Front", in: .window, group: 2,
      action: #selector(NSApplication.arrangeInFront(_:))),
  ]

  /// Shortcuts bound to more than one command, each with the ids that share it.
  public static func conflicts(in commands: [Command]) -> [Shortcut: [String]] {
    let bound = commands.compactMap { command in command.shortcut.map { ($0, [command.id]) } }
    return Dictionary(bound, uniquingKeysWith: +).filter { $0.value.count > 1 }
  }
}

/// The menu bar for `commands`, one menu per `MenuName` that has any.
@MainActor
public func menuBar(for commands: [Command] = Command.all) -> NSMenu {
  let bar = NSMenu()
  for name in MenuName.allCases {
    let entries = commands.filter { $0.menu == name }
    guard !entries.isEmpty else { continue }
    let menu = NSMenu(title: name.rawValue)
    for (index, command) in entries.enumerated() {
      if index > 0, entries[index - 1].group != command.group {
        menu.addItem(.separator())
      }
      let item = NSMenuItem(
        title: command.title, action: command.action,
        keyEquivalent: command.shortcut?.key ?? "")
      item.keyEquivalentModifierMask = command.shortcut?.modifierFlags ?? []
      item.identifier = NSUserInterfaceItemIdentifier(command.id)
      menu.addItem(item)
    }
    let holder = NSMenuItem(title: name.rawValue, action: nil, keyEquivalent: "")
    holder.submenu = menu
    bar.addItem(holder)
  }
  return bar
}

/// Installs the menu bar and tells AppKit which menu lists the windows.
@MainActor
public func installMenuBar(in app: NSApplication) {
  let bar = menuBar()
  app.mainMenu = bar
  app.windowsMenu = bar.item(withTitle: MenuName.window.rawValue)?.submenu
}
