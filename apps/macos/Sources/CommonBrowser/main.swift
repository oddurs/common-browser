import AppKit
import CommonApp
import WebKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
  private var window: NSWindow?

  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.mainMenu = mainMenu()
    let webView = WKWebView()
    webView.load(URLRequest(url: startURL(arguments: CommandLine.arguments)))

    // The page owns the window: no toolbar, a transparent title bar, content under it.
    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 1280, height: 800),
      styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
      backing: .buffered,
      defer: false
    )
    window.titlebarAppearsTransparent = true
    window.titleVisibility = .hidden
    window.contentView = webView
    window.center()
    window.makeKeyAndOrderFront(nil)
    self.window = window
    NSApp.activate()
  }

  @objc func showAbout(_ sender: Any?) {
    NSApp.orderFrontStandardAboutPanel(options: aboutPanelOptions())
  }

  // Only what an app cannot do without; the command registry builds the full menu bar.
  private func mainMenu() -> NSMenu {
    let appMenu = NSMenu()
    appMenu.addItem(
      withTitle: "About Common Browser", action: #selector(showAbout(_:)), keyEquivalent: "")
    appMenu.addItem(.separator())
    appMenu.addItem(
      withTitle: "Quit Common Browser", action: #selector(NSApplication.terminate(_:)),
      keyEquivalent: "q")
    let appItem = NSMenuItem()
    appItem.submenu = appMenu
    let menu = NSMenu()
    menu.addItem(appItem)
    return menu
  }

  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    true
  }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
