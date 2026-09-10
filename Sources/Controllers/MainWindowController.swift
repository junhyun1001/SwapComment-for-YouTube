import Cocoa

class MainWindowController: NSWindowController, NSWindowDelegate {
    let mainViewController = MainViewController()
    var onWindowWillClose: ((MainWindowController) -> Void)?

    var groupId: String {
        get { window?.tabbingIdentifier ?? "" }
        set { window?.tabbingIdentifier = newValue }
    }

    convenience init(groupId: String) {
        let screenSize = NSScreen.main?.visibleFrame.size ?? CGSize(width: 1440, height: 900)
        let defaultWidth: CGFloat = min(1360, screenSize.width * 0.85)
        let defaultHeight: CGFloat = min(880, screenSize.height * 0.85)

        let windowRect = NSRect(
            x: (screenSize.width - defaultWidth) / 2,
            y: (screenSize.height - defaultHeight) / 2,
            width: defaultWidth,
            height: defaultHeight
        )

        let window = MainWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "SwapComment for YouTube"
        window.titleVisibility = .hidden
        window.titlebarSeparatorStyle = .none
        window.backgroundColor = NSColor(red: 15/255, green: 15/255, blue: 15/255, alpha: 1.0)
        window.minSize = NSSize(width: 900, height: 550)
        window.isReleasedWhenClosed = false
        window.tabbingIdentifier = groupId
        window.tabbingMode = .preferred

        self.init(window: window)
        window.delegate = self
        window.contentViewController = mainViewController
    }

    func windowWillClose(_ notification: Notification) {
        onWindowWillClose?(self)
    }

    // Handle "+" button on macOS native tab bar
    override func newWindowForTab(_ sender: Any?) {
        (NSApplication.shared.delegate as? AppDelegate)?.newTab()
    }
}
