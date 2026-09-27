import AppKit

/// A one-line message over the bottom of a window, such as a download finishing. Each window has
/// at most one: a new message replaces the old one rather than stacking.
final class NoticeView: NSVisualEffectView {
  static let identifier = NSUserInterfaceItemIdentifier("notice")

  private let label = NSTextField(labelWithString: "")
  // Each message bumps this, so the timer of a message already replaced cannot hide the new one.
  private var generation = 0

  var text: String { label.stringValue }

  init() {
    super.init(frame: .zero)
    identifier = Self.identifier
    material = .hudWindow
    blendingMode = .withinWindow
    state = .active
    wantsLayer = true
    layer?.cornerRadius = 8
    translatesAutoresizingMaskIntoConstraints = false
    label.font = .systemFont(ofSize: NSFont.systemFontSize)
    label.lineBreakMode = .byTruncatingMiddle
    label.translatesAutoresizingMaskIntoConstraints = false
    addSubview(label)
    NSLayoutConstraint.activate([
      label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
      label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
      label.topAnchor.constraint(equalTo: topAnchor, constant: 6),
      label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -6),
    ])
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("NoticeView is created in code")
  }

  /// Shows `text`, then removes the notice after `duration`, or leaves it until the next message
  /// if `duration` is nil.
  func show(_ text: String, for duration: Duration?) {
    label.stringValue = text
    setAccessibilityLabel(text)
    generation += 1
    guard let duration else { return }
    let shown = generation
    Task { @MainActor [weak self] in
      try? await Task.sleep(for: duration)
      guard let self, self.generation == shown else { return }
      self.removeFromSuperview()
    }
  }
}

/// Shows `text` over the bottom of `window`, replacing any notice already there.
@MainActor
func showNotice(_ text: String, in window: NSWindow, for duration: Duration? = .seconds(4)) {
  guard let content = window.contentView else { return }
  let notice =
    content.subviews.first { $0.identifier == NoticeView.identifier } as? NoticeView
    ?? {
      let notice = NoticeView()
      content.addSubview(notice)
      NSLayoutConstraint.activate([
        notice.centerXAnchor.constraint(equalTo: content.centerXAnchor),
        notice.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -24),
        notice.widthAnchor.constraint(lessThanOrEqualTo: content.widthAnchor, constant: -48),
      ])
      return notice
    }()
  notice.show(text, for: duration)
}
