import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  var statusItem: NSStatusItem?
  
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // Keep app running - don't terminate when window closes
    return false
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
  
  override func applicationDidFinishLaunching(_ notification: Notification) {
    // Create menu bar icon for background mode
    statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    if let button = statusItem?.button {
      // Use a simple text icon for compatibility
      button.title = "📋"
      button.toolTip = "Clipboard Manager"
    }
    
    // Create menu
    let menu = NSMenu()
    
    menu.addItem(NSMenuItem(title: "Show Clipboard", action: #selector(showWindow), keyEquivalent: ""))
    menu.addItem(NSMenuItem.separator())
    menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
    
    statusItem?.menu = menu
  }
  
  @objc func showWindow() {
    // Show the main window
    if let window = NSApplication.shared.windows.first {
      window.makeKeyAndOrderFront(nil)
      NSApp.activate(ignoringOtherApps: true)
    }
  }
}
