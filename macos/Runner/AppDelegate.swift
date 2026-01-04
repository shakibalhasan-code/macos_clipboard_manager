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
    
    // Explicitly check for accessibility permissions to force app appearance in System Settings
    let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
    let accessEnabled = AXIsProcessTrustedWithOptions(options)
    
    if !accessEnabled {
      print("Accessibility not enabled. Prompting user.")
    }

    // Create menu
    let menu = NSMenu()
    
    menu.addItem(NSMenuItem(title: "Show Clipboard", action: #selector(showWindow), keyEquivalent: ""))
    menu.addItem(NSMenuItem.separator())
    menu.addItem(NSMenuItem(title: "Quit Clipboard Manager", action: #selector(quitApp), keyEquivalent: "q"))
    
    statusItem?.menu = menu

    // Set up MethodChannel for permission checking
    let controller: FlutterViewController = mainFlutterWindow?.contentViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "com.clipboardmanager.macos/permissions",
                                      binaryMessenger: controller.engine.binaryMessenger)
    
    channel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "checkAccessibilityPermission" {
        // Check without checking for prompt
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : false]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        print("Accessibility check requested: \(accessEnabled)")
        result(accessEnabled)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })
  }
  
  @objc func showWindow() {
    // Show and focus the main window
    // We intentionally don't rely on NSApplication.shared.windows.first as it might be unreliable
    // Instead we activate the app which brings the window forward
    NSApp.activate(ignoringOtherApps: true)
    
    if let window = NSApplication.shared.windows.first {
      window.makeKeyAndOrderFront(nil)
      window.orderFrontRegardless()
    }
  }
  
  @objc func quitApp() {
    NSApplication.shared.terminate(nil)
  }
}
