import Cocoa

class MainWindow: NSWindow {
    override func keyDown(with event: NSEvent) {
        // Prevent default macOS alert sound (NSBeep) when YouTube web shortcuts
        // (e.g. j, k, l, space, arrow keys, numbers) are handled by JavaScript in WKWebView
        // but not consumed by the native responder chain.
    }
}
