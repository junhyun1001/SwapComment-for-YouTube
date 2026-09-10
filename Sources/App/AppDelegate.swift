import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate, AppMenuActionDelegate, ViewMenuActionDelegate {
    var windowControllers: [MainWindowController] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
        NSApplication.shared.mainMenu = MenuBuilder.build(appDelegate: self)
        newWindow()
    }

    // MARK: - AppMenuActionDelegate (Cmd+N: New Independent Window)
    @objc func newWindow() {
        let controller = MainWindowController(groupId: UUID().uuidString)
        setupController(controller)

        if let keyWindow = NSApplication.shared.keyWindow,
           let newWindow = controller.window {
            let currentTopLeft = NSPoint(x: keyWindow.frame.minX, y: keyWindow.frame.maxY)
            let nextPoint = newWindow.cascadeTopLeft(from: currentTopLeft)
            newWindow.setFrameTopLeftPoint(nextPoint)
        }

        controller.window?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    // MARK: - AppMenuActionDelegate (Cmd+T: New Tab inside Current Window)
    @objc func newTab() {
        guard let keyWindow = NSApplication.shared.keyWindow ?? windowControllers.first?.window,
              let hostController = windowControllers.first(where: { $0.window === keyWindow }) else {
            newWindow()
            return
        }

        let controller = MainWindowController(groupId: hostController.groupId)
        setupController(controller)

        if let newWindow = controller.window {
            keyWindow.addTabbedWindow(newWindow, ordered: .above)
            newWindow.makeKeyAndOrderFront(nil)
        } else {
            controller.window?.makeKeyAndOrderFront(nil)
        }
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func setupController(_ controller: MainWindowController) {
        controller.onWindowWillClose = { [weak self, weak controller] closedController in
            guard let self = self, let controller = controller else { return }
            self.windowControllers.removeAll { $0 === controller }
        }
        windowControllers.append(controller)
    }

    // MARK: - Active View Controller Dispatcher for View Menu
    private var activeViewController: MainViewController? {
        if let keyWindow = NSApplication.shared.keyWindow,
           let controller = windowControllers.first(where: { $0.window === keyWindow }) {
            return controller.mainViewController
        }
        return windowControllers.first?.mainViewController
    }

    // MARK: - ViewMenuActionDelegate
    @objc func reloadPage() {
        activeViewController?.reloadPage()
    }

    @objc func goBack() {
        activeViewController?.goBack()
    }

    @objc func goForward() {
        activeViewController?.goForward()
    }

    @objc func zoomActual() {
        activeViewController?.zoomActual()
    }

    @objc func zoomIn() {
        activeViewController?.zoomIn()
    }

    @objc func zoomOut() {
        activeViewController?.zoomOut()
    }

    @objc func toggleFullScreen() {
        activeViewController?.toggleFullScreen()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}
