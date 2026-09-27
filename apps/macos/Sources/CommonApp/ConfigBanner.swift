import AppKit

/// A small notice at the top of the window saying what is wrong with `common.toml`. Open sends
/// `openConfig` up the responder chain; the close button dismisses it until the next launch.
@MainActor
final class ConfigBanner: NSVisualEffectView {
  let label: NSTextField

  init(text: String) {
    label = NSTextField(labelWithString: text)
    super.init(frame: .zero)
    translatesAutoresizingMaskIntoConstraints = false
    material = .hudWindow
    blendingMode = .withinWindow
    state = .active
    wantsLayer = true
    layer?.cornerRadius = 10
    layer?.masksToBounds = true

    label.font = .systemFont(ofSize: 12)
    label.lineBreakMode = .byTruncatingTail
    label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
    let open = NSButton(
      title: "Open", target: nil, action: #selector(BrowserActions.openConfig(_:)))
    open.controlSize = .small
    open.bezelStyle = .push
    let close = NSButton(
      image: NSImage(systemSymbolName: "xmark", accessibilityDescription: "Dismiss")!,
      target: self, action: #selector(dismiss(_:)))
    close.isBordered = false

    let row = NSStackView(views: [label, open, close])
    row.spacing = 10
    row.edgeInsets = NSEdgeInsets(top: 6, left: 12, bottom: 6, right: 8)
    row.translatesAutoresizingMaskIntoConstraints = false
    addSubview(row)
    NSLayoutConstraint.activate([
      row.leadingAnchor.constraint(equalTo: leadingAnchor),
      row.trailingAnchor.constraint(equalTo: trailingAnchor),
      row.topAnchor.constraint(equalTo: topAnchor),
      row.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])
    setAccessibilityRole(.group)
    setAccessibilityLabel(text)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("ConfigBanner is created in code")
  }

  @objc private func dismiss(_ sender: Any?) {
    removeFromSuperview()
  }
}
