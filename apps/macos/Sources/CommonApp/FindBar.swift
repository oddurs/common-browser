import AppKit

/// The find field: a small glass capsule at the top centre of the window, where the capsule that
/// shows the address will sit. It only draws and reports keys; searching is the window's job.
@MainActor
public final class FindBar: NSVisualEffectView, NSTextFieldDelegate {
  public let field = NSTextField()
  let statusLabel = NSTextField(labelWithString: "")

  /// The query changed: search again from the current match.
  var onChange: (String) -> Void = { _ in }
  /// Return and Shift-Return, like ⌘G and ⇧⌘G.
  var onStep: (_ backwards: Bool) -> Void = { _ in }
  /// Esc.
  var onClose: () -> Void = {}

  static let height: CGFloat = 30

  public init() {
    super.init(frame: NSRect(x: 0, y: 0, width: 300, height: FindBar.height))
    isHidden = true
    material = .popover
    blendingMode = .withinWindow
    state = .active
    wantsLayer = true
    layer?.cornerRadius = FindBar.height / 2
    layer?.cornerCurve = .continuous
    layer?.masksToBounds = true

    field.placeholderString = "Find in page"
    field.isBordered = false
    field.drawsBackground = false
    field.focusRingType = .none
    field.font = .systemFont(ofSize: NSFont.systemFontSize)
    field.lineBreakMode = .byClipping
    field.cell?.isScrollable = true
    field.delegate = self

    statusLabel.font = .monospacedDigitSystemFont(
      ofSize: NSFont.smallSystemFontSize, weight: .regular)
    statusLabel.textColor = .secondaryLabelColor
    statusLabel.alignment = .right
    statusLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    statusLabel.setContentHuggingPriority(.required, for: .horizontal)

    let row = NSStackView(views: [field, statusLabel])
    row.orientation = .horizontal
    row.alignment = .centerY
    row.spacing = 8
    row.edgeInsets = NSEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
    row.translatesAutoresizingMaskIntoConstraints = false
    addSubview(row)
    NSLayoutConstraint.activate([
      row.leadingAnchor.constraint(equalTo: leadingAnchor),
      row.trailingAnchor.constraint(equalTo: trailingAnchor),
      row.topAnchor.constraint(equalTo: topAnchor),
      row.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("FindBar is created in code")
  }

  public var query: String { field.stringValue }

  public var status: FindStatus = .idle {
    didSet { statusLabel.stringValue = status.text }
  }

  public func controlTextDidChange(_ notification: Notification) {
    onChange(query)
  }

  /// Handles Return, Shift-Return and Esc. Returning true for each keeps the field editor from
  /// acting on them, and from beeping.
  public func control(
    _ control: NSControl, textView: NSTextView, doCommandBy selector: Selector
  ) -> Bool {
    switch selector {
    case #selector(NSResponder.insertNewline(_:)):
      onStep(NSApp.currentEvent?.modifierFlags.contains(.shift) ?? false)
    case #selector(NSResponder.cancelOperation(_:)):
      onClose()
    default:
      return false
    }
    return true
  }
}
