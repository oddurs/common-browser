import AppKit
import Testing

@testable import CommonApp

@Test func noTwoCommandsShareAShortcut() {
  #expect(Command.conflicts(in: Command.all).isEmpty)
}

@Test func theConflictCheckCatchesASharedShortcut() {
  let clash =
    Command.all + [
      Command(
        "extra", "Extra", in: .file, shortcut: Shortcut("t"), action: #selector(NSText.copy(_:)))
    ]
  #expect(Command.conflicts(in: clash)[Shortcut("t")]?.sorted() == ["extra", "new-page"])
}

@Test func commandIdsAreUnique() {
  let ids = Command.all.map(\.id)
  #expect(Set(ids).count == ids.count)
}

@MainActor
@Test func addingACommandAddsItsMenuItemAndShortcut() throws {
  let extra = Command(
    "extra", "Extra Thing", in: .view, shortcut: Shortcut("e", [.option, .command]),
    action: #selector(NSText.copy(_:)))
  let item = try #require(
    items(in: menuBar(for: Command.all + [extra])).first { $0.title == "Extra Thing" })
  #expect(item.keyEquivalent == "e")
  #expect(item.keyEquivalentModifierMask == [.option, .command])
  #expect(item.identifier?.rawValue == "extra")
}

@MainActor
@Test func theV01ShortcutsAppearInTheMenus() {
  let shown = Set(
    items(in: menuBar()).compactMap { item in
      Command.all.first { $0.id == item.identifier?.rawValue }?.shortcut?.symbols
    })
  for expected in ["⌘T", "⌘W", "⌘L", "⌘[", "⌘]", "⌘R", "⇧⌘C", "⌘F", "⌘,", "⌃⌘F"] {
    #expect(shown.contains(expected), "\(expected) is not in the menu bar")
  }
}

@MainActor
@Test func menusFollowTheMenuBarOrderAndSeparateGroups() throws {
  let bar = menuBar()
  #expect(bar.items.map(\.title) == MenuName.allCases.map(\.rawValue))
  let file = try #require(bar.item(withTitle: "File")?.submenu)
  #expect(
    file.items.map { $0.isSeparatorItem ? "-" : $0.title } == [
      "New Page", "Open Location…", "-", "Close Page",
    ])
}

@Test func arrowShortcutsReadAsArrows() {
  #expect(Shortcut(Shortcut.leftArrow, [.option, .command]).symbols == "⌥⌘←")
}

/// Every item in every submenu.
@MainActor
private func items(in bar: NSMenu) -> [NSMenuItem] {
  bar.items.flatMap { $0.submenu?.items ?? [] }
}
