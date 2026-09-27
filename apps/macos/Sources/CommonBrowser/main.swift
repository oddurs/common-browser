import AppKit
import CommonApp

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, BrowserActions {
  private var windowController: BrowserWindowController?

  func applicationDidFinishLaunching(_ notification: Notification) {
    // Pages are the browser's tabs; AppKit's window tabs would add a second, competing kind, and
    // their Show Tab Bar items to the menus.
    NSWindow.allowsAutomaticWindowTabbing = false
    installMenuBar(in: NSApp)
    let controller = BrowserWindowController(url: startURL(arguments: CommandLine.arguments))
    controller.showWindow(nil)
    windowController = controller
    NSApp.activate()
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
