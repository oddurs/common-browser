import AppKit

/// A row the launcher lists.
enum LauncherRow: Equatable {
  /// Where the typed text leads: "Go to example.org" or "Search for what is rust".
  case go(String)
  /// An open page the text names.
  case page(id: UInt64, title: String, site: String)
}

/// The launcher: one field over the page and the rows it names below. The first row is always what
/// Return does with the text itself, so a word that also matches a page title still searches;
/// the arrow keys move to a page. The panel only reports the choice; the window acts on it.
@MainActor
public final class LauncherPanel: NSVisualEffectView, NSTextFieldDelegate {
  static let width: CGFloat = 640
  static let maxRows = 8

  let field = NSTextField()
  private let list = NSStackView()
  private(set) var rows: [LauncherRow] = []
  private(set) var selection = 0

  var onChange: ((String) -> Void)?
  var onGo: ((String) -> Void)?
  var onPick: ((UInt64) -> Void)?
  var onCancel: (() -> Void)?

  init() {
    super.init(frame: .zero)
    translatesAutoresizingMaskIntoConstraints = false
    material = .popover
    blendingMode = .withinWindow
    state = .active
    wantsLayer = true
    layer?.cornerRadius = 18
    layer?.masksToBounds = true

    field.isBordered = false
    field.drawsBackground = false
    field.focusRingType = .none
    field.font = .systemFont(ofSize: 20)
    field.placeholderString = "Search or enter an address"
    field.delegate = self
    field.setAccessibilityLabel("Launcher")

    list.orientation = .vertical
    list.alignment = .leading
    list.spacing = 2

    let column = NSStackView(views: [field, list])
    column.orientation = .vertical
    column.alignment = .leading
    column.spacing = 8
    column.edgeInsets = NSEdgeInsets(top: 14, left: 16, bottom: 12, right: 16)
    column.translatesAutoresizingMaskIntoConstraints = false
    addSubview(column)
    NSLayoutConstraint.activate([
      widthAnchor.constraint(equalToConstant: Self.width),
      column.leadingAnchor.constraint(equalTo: leadingAnchor),
      column.trailingAnchor.constraint(equalTo: trailingAnchor),
      column.topAnchor.constraint(equalTo: topAnchor),
      column.bottomAnchor.constraint(equalTo: bottomAnchor),
      field.widthAnchor.constraint(equalTo: column.widthAnchor, constant: -32),
      list.widthAnchor.constraint(equalTo: column.widthAnchor, constant: -32),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("LauncherPanel is created in code")
  }

  /// Shows `rows`, selecting the first.
  func show(_ rows: [LauncherRow]) {
    self.rows = Array(rows.prefix(Self.maxRows))
    selection = 0
    redraw()
  }

  public func controlTextDidChange(_ notification: Notification) {
    onChange?(field.stringValue)
  }

  public func control(
    _ control: NSControl, textView: NSTextView, doCommandBy selector: Selector
  ) -> Bool {
    switch selector {
    case #selector(NSResponder.moveDown(_:)):
      move(by: 1)
    case #selector(NSResponder.moveUp(_:)):
      move(by: -1)
    case #selector(NSResponder.insertNewline(_:)):
      choose()
    case #selector(NSResponder.cancelOperation(_:)):
      onCancel?()
    default:
      return false
    }
    return true
  }

  private func move(by step: Int) {
    guard !rows.isEmpty else { return }
    selection = min(max(selection + step, 0), rows.count - 1)
    redraw()
  }

  private func choose() {
    guard rows.indices.contains(selection) else { return }
    switch rows[selection] {
    case .go: onGo?(field.stringValue)
    case .page(let id, _, _): onPick?(id)
    }
  }

  private func redraw() {
    for view in list.arrangedSubviews {
      view.removeFromSuperview()
    }
    list.isHidden = rows.isEmpty
    for (index, row) in rows.enumerated() {
      list.addArrangedSubview(rowView(row, selected: index == selection))
    }
  }

  private func rowView(_ row: LauncherRow, selected: Bool) -> NSView {
    let title: String
    let detail: String
    switch row {
    case .go(let text):
      title = text
      detail = ""
    case .page(_, let pageTitle, let site):
      title = pageTitle.isEmpty ? site : pageTitle
      detail = site
    }
    let titleLabel = NSTextField(labelWithString: title)
    titleLabel.font = .systemFont(ofSize: 13)
    titleLabel.lineBreakMode = .byTruncatingTail
    let detailLabel = NSTextField(labelWithString: detail)
    detailLabel.font = .systemFont(ofSize: 12)
    detailLabel.textColor = .secondaryLabelColor
    detailLabel.lineBreakMode = .byTruncatingTail
    let line = NSStackView(views: [titleLabel, detailLabel])
    line.spacing = 8
    line.edgeInsets = NSEdgeInsets(top: 5, left: 8, bottom: 5, right: 8)
    line.wantsLayer = true
    line.layer?.cornerRadius = 6
    line.layer?.backgroundColor =
      selected ? NSColor.selectedContentBackgroundColor.withAlphaComponent(0.25).cgColor : nil
    line.setAccessibilityRole(.row)
    line.setAccessibilityLabel(detail.isEmpty ? title : "\(title), \(detail)")
    line.setAccessibilitySelected(selected)
    return line
  }
}
