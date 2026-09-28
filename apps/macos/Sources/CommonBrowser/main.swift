import AppKit
import CommonApp
import CommonCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, BrowserActions {
  private var windowController: BrowserWindowController?

  func applicationDidFinishLaunching(_ notification: Notification) {
    // Pages are the browser's tabs; AppKit's window tabs would add a second, competing kind, and
    // their Show Tab Bar items to the menus.
    NSWindow.allowsAutomaticWindowTabbing = false
    installMenuBar(in: NSApp)
    let loaded = loadConfig()
    let home = URL(string: loaded.settings.home) ?? URL(string: "about:blank")!
    let controller = BrowserWindowController(
      url: startURL(arguments: CommandLine.arguments, home: home), home: home,
      searchEngine: loaded.settings.searchEngine)
    controller.showWindow(nil)
    if let text = configBannerText(for: loaded) {
      controller.showConfigBanner(text)
    }
    if loaded.settings.startFullScreen {
      controller.window?.toggleFullScreen(nil)
    }
    windowController = controller
    NSApp.activate()
  }

  func openConfig(_ sender: Any?) {
    do {
      try openConfigFile(open: openInEditor)
    } catch {
      NSApp.presentError(error)
    }
  }

  func showAbout(_ sender: Any?) {
    NSApp.orderFrontStandardAboutPanel(options: aboutPanelOptions())
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
