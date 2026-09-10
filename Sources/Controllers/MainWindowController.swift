import Cocoa

class MainWindowController: NSWindowController, NSWindowDelegate {
    convenience init(window: NSWindow) {
        self.init()
        self.window = window
        window.delegate = self
    }

    func windowShouldClose(_ sender: NSWindow) -> Bool {
        NSApplication.shared.terminate(nil)
        return true
    }
}
