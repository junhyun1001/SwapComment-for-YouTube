import Cocoa

class MainWindowController: NSWindowController, NSWindowDelegate {
    private static let windowFrameDefaultsKey = "savedMainWindowFrame"
    private static let minWindowSize = NSSize(width: 640, height: 480)
    let mainViewController = MainViewController()
    var onWindowWillClose: ((MainWindowController) -> Void)?
    private var saveFrameWorkItem: DispatchWorkItem?

    var groupId: String {
        get { window?.tabbingIdentifier ?? "" }
        set { window?.tabbingIdentifier = newValue }
    }

    convenience init(groupId: String) {
        let visibleFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let defaultWidth: CGFloat = min(1360, visibleFrame.width * 0.85)
        let defaultHeight: CGFloat = min(880, visibleFrame.height * 0.85)

        let defaultRect = NSRect(
            x: visibleFrame.origin.x + (visibleFrame.width - defaultWidth) / 2,
            y: visibleFrame.origin.y + (visibleFrame.height - defaultHeight) / 2,
            width: defaultWidth,
            height: defaultHeight
        )

        let window = MainWindow(
            contentRect: defaultRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "SwapComment for YouTube"
        window.titleVisibility = .hidden
        window.titlebarSeparatorStyle = .none
        window.backgroundColor = NSColor(red: 15/255, green: 15/255, blue: 15/255, alpha: 1.0)
        window.minSize = Self.minWindowSize
        window.isReleasedWhenClosed = false
        window.tabbingIdentifier = groupId
        window.tabbingMode = .preferred

        self.init(window: window)
        window.contentViewController = mainViewController
        if let savedFrame = Self.loadSavedWindowFrame() {
            window.setFrame(savedFrame, display: true)
        } else {
            window.setContentSize(defaultRect.size)
            window.setFrameOrigin(defaultRect.origin)
        }
        window.delegate = self
    }

    private static func loadSavedWindowFrame() -> NSRect? {
        guard let raw = UserDefaults.standard.string(forKey: windowFrameDefaultsKey) else {
            return nil
        }
        let rect = NSRectFromString(raw)
        guard rect.width >= minWindowSize.width, rect.height >= minWindowSize.height else {
            return nil
        }
        let targetScreen = NSScreen.screens
            .filter { $0.visibleFrame.intersects(rect) }
            .max { lhs, rhs in
                let lhsArea = lhs.visibleFrame.intersection(rect)
                let rhsArea = rhs.visibleFrame.intersection(rect)
                return (lhsArea.width * lhsArea.height) < (rhsArea.width * rhsArea.height)
            }
        guard let visible = targetScreen?.visibleFrame else {
            return nil
        }
        let width = min(rect.width, visible.width)
        let height = min(rect.height, visible.height)
        let x = max(visible.minX, min(rect.origin.x, visible.maxX - width))
        let y = max(visible.minY, min(rect.origin.y, visible.maxY - height))
        return NSRect(x: x, y: y, width: width, height: height)
    }

    func saveWindowFrame() {
        saveFrameWorkItem?.cancel()
        saveFrameWorkItem = nil
        guard let window = window, !window.styleMask.contains(.fullScreen) else {
            return
        }
        UserDefaults.standard.set(NSStringFromRect(window.frame), forKey: Self.windowFrameDefaultsKey)
    }

    private func scheduleSaveWindowFrame() {
        saveFrameWorkItem?.cancel()
        let item = DispatchWorkItem { [weak self] in
            self?.saveWindowFrame()
        }
        saveFrameWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: item)
    }

    func windowDidMove(_ notification: Notification) {
        scheduleSaveWindowFrame()
    }

    func windowDidResize(_ notification: Notification) {
        scheduleSaveWindowFrame()
    }

    func windowDidEndLiveResize(_ notification: Notification) {
        saveWindowFrame()
        mainViewController.syncLayoutAfterResize()
    }

    func windowWillClose(_ notification: Notification) {
        saveWindowFrame()
        onWindowWillClose?(self)
    }

    // Handle "+" button on macOS native tab bar
    override func newWindowForTab(_ sender: Any?) {
        (NSApplication.shared.delegate as? AppDelegate)?.newTab()
    }
}
