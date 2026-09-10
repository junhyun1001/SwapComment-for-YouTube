import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    var mainWindowController: MainWindowController!

    func applicationDidFinishLaunching(_ notification: Notification) {
        mainWindowController = MainWindowController()
        mainWindowController.showWindow(nil)

        NSApplication.shared.mainMenu = MenuBuilder.build(target: mainWindowController.mainViewController)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
