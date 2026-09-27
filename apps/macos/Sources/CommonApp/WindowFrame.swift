import AppKit

/// Where a restored window may go. A saved frame can outlive the display it was on (a laptop
/// unplugged from its monitor), and a window whose title bar is off every screen cannot be grabbed
/// to move it back; such a frame is shrunk to fit and centred on the first screen instead.
public func fitted(_ frame: NSRect, into screens: [NSRect]) -> NSRect {
  // Enough of the top edge to grab: the title bar is where a window is dragged from.
  let grip = NSRect(x: frame.minX, y: frame.maxY - 24, width: frame.width, height: 24)
  if screens.contains(where: { $0.intersection(grip).width >= 80 }) {
    return frame
  }
  guard let screen = screens.first else { return frame }
  let size = NSSize(
    width: min(frame.width, screen.width), height: min(frame.height, screen.height))
  return NSRect(
    x: screen.midX - size.width / 2, y: screen.midY - size.height / 2,
    width: size.width, height: size.height)
}
