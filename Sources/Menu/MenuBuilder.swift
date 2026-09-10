import Cocoa

@objc protocol AppMenuActionDelegate: AnyObject {
    func newWindow()
    func newTab()
}

@objc protocol ViewMenuActionDelegate: AnyObject {
    func reloadPage()
    func goBack()
    func goForward()
    func zoomActual()
    func zoomIn()
    func zoomOut()
    func toggleFullScreen()
}

final class MenuBuilder {
    static func build(appDelegate: (AppMenuActionDelegate & ViewMenuActionDelegate)?) -> NSMenu {
        let mainMenu = NSMenu()

        // 1. Application Menu
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "About SwapComment for YouTube", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Hide SwapComment for YouTube", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthersItem = NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthersItem.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(hideOthersItem)
        appMenu.addItem(withTitle: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit SwapComment for YouTube", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // 2. File Menu (New Window, New Tab, Close Window)
        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "File")

        let newWindowItem = fileMenu.addItem(withTitle: "New Window", action: #selector(AppMenuActionDelegate.newWindow), keyEquivalent: "n")
        newWindowItem.target = appDelegate

        let newTabItem = fileMenu.addItem(withTitle: "New Tab", action: #selector(AppMenuActionDelegate.newTab), keyEquivalent: "t")
        newTabItem.target = appDelegate

        fileMenu.addItem(NSMenuItem.separator())

        fileMenu.addItem(withTitle: "Close Window", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

        // 3. Edit Menu (Crucial for Copy, Paste, Select All in WebViews)
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: #selector(UndoManager.undo), keyEquivalent: "z")
        let redoItem = NSMenuItem(title: "Redo", action: #selector(UndoManager.redo), keyEquivalent: "Z")
        redoItem.keyEquivalentModifierMask = [.command, .shift]
        editMenu.addItem(redoItem)
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        // 4. View Menu (Navigation, Reload, Fullscreen)
        let viewMenuItem = NSMenuItem()
        let viewMenu = NSMenu(title: "View")

        let reloadItem = viewMenu.addItem(withTitle: "Reload", action: #selector(ViewMenuActionDelegate.reloadPage), keyEquivalent: "r")
        reloadItem.target = appDelegate

        let backItem = viewMenu.addItem(withTitle: "Back", action: #selector(ViewMenuActionDelegate.goBack), keyEquivalent: "[")
        backItem.target = appDelegate

        let forwardItem = viewMenu.addItem(withTitle: "Forward", action: #selector(ViewMenuActionDelegate.goForward), keyEquivalent: "]")
        forwardItem.target = appDelegate

        viewMenu.addItem(NSMenuItem.separator())

        let actualSizeItem = viewMenu.addItem(withTitle: "Actual Size", action: #selector(ViewMenuActionDelegate.zoomActual), keyEquivalent: "0")
        actualSizeItem.target = appDelegate

        let zoomInItem = viewMenu.addItem(withTitle: "Zoom In", action: #selector(ViewMenuActionDelegate.zoomIn), keyEquivalent: "+")
        zoomInItem.target = appDelegate

        let zoomOutItem = viewMenu.addItem(withTitle: "Zoom Out", action: #selector(ViewMenuActionDelegate.zoomOut), keyEquivalent: "-")
        zoomOutItem.target = appDelegate

        viewMenu.addItem(NSMenuItem.separator())

        let fullScreenItem = NSMenuItem(title: "Toggle Full Screen", action: #selector(ViewMenuActionDelegate.toggleFullScreen), keyEquivalent: "f")
        fullScreenItem.keyEquivalentModifierMask = [.command, .control]
        fullScreenItem.target = appDelegate
        viewMenu.addItem(fullScreenItem)

        viewMenuItem.submenu = viewMenu
        mainMenu.addItem(viewMenuItem)

        // 5. Window Menu
        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: "Window")
        windowMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        windowMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        return mainMenu
    }
}
