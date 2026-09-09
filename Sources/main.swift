import Cocoa
import WebKit

class PopupWebViewController: NSViewController, WKUIDelegate, WKNavigationDelegate {
    var webView: WKWebView!
    var onLoginFinished: (() -> Void)?
    private var isClosing = false

    override func loadView() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default()
        webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15"
        webView.uiDelegate = self
        webView.navigationDelegate = self
        self.view = webView
    }

    func webViewDidClose(_ webView: WKWebView) {
        closePopup()
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url {
            let host = url.host?.lowercased() ?? ""
            // When Google completes OAuth, it redirects to YouTube.
            // If it lands back on YouTube main or home page (not intermediary signin endpoints):
            if host.contains("youtube.com") && !url.path.contains("signin") {
                decisionHandler(.cancel)
                closePopup()
                return
            }
        }
        // Force WebKit to allow navigation internally without deferring to macOS Universal Links / Safari PWA
        let allowPolicy = WKNavigationActionPolicy(rawValue: WKNavigationActionPolicy.allow.rawValue + 2) ?? .allow
        decisionHandler(allowPolicy)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if let url = webView.url {
            let host = url.host?.lowercased() ?? ""
            if host.contains("youtube.com") && !url.path.contains("signin") {
                closePopup()
            }
        }
    }

    private func closePopup() {
        guard !isClosing else { return }
        isClosing = true
        DispatchQueue.main.async { [weak self] in
            self?.onLoginFinished?()
            self?.view.window?.close()
        }
    }
}

class MainWindow: NSWindow {
    override func keyDown(with event: NSEvent) {
        // Prevent default macOS alert sound (NSBeep) when YouTube web shortcuts
        // (e.g. j, k, l, space, arrow keys, numbers) are handled by JavaScript in WKWebView
        // but not consumed by the native responder chain.
    }
}

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




class AppDelegate: NSObject, NSApplicationDelegate, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    var window: NSWindow!
    var windowController: MainWindowController!
    var webView: WKWebView!
    var popupWindows: [NSWindow] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenu()
        setupWindow()
        setupWebView()
        loadYouTube()
    }

    func setupWindow() {
        let screenSize = NSScreen.main?.visibleFrame.size ?? CGSize(width: 1440, height: 900)
        let defaultWidth: CGFloat = min(1360, screenSize.width * 0.85)
        let defaultHeight: CGFloat = min(880, screenSize.height * 0.85)

        let windowRect = NSRect(
            x: (screenSize.width - defaultWidth) / 2,
            y: (screenSize.height - defaultHeight) / 2,
            width: defaultWidth,
            height: defaultHeight
        )

        window = MainWindow(
            contentRect: windowRect,
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "SwapComment for YouTube"
        window.titleVisibility = .hidden
        window.titlebarSeparatorStyle = .none
        window.backgroundColor = NSColor(red: 15/255, green: 15/255, blue: 15/255, alpha: 1.0) // YouTube dark bg
        window.minSize = NSSize(width: 900, height: 550)
        window.isReleasedWhenClosed = false
        window.setFrameAutosaveName("SwapCommentMainWindow")

        windowController = MainWindowController(window: window)
        window.makeKeyAndOrderFront(nil)
    }

    func setupWebView() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default() // Persistent session & cookies
        config.allowsAirPlayForMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let userContentController = WKUserContentController()

        // 1. Inject custom CSS
        if let cssPath = Bundle.main.path(forResource: "style", ofType: "css"),
           let cssContent = try? String(contentsOfFile: cssPath, encoding: .utf8) {
            let cssScript = """
            (function() {
                var style = document.createElement('style');
                style.id = 'switch-video-to-comment-style';
                style.textContent = `\(cssContent.replacingOccurrences(of: "`", with: "\\`"))`;
                (document.head || document.documentElement).appendChild(style);
            })();
            """
            let userScript = WKUserScript(source: cssScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            userContentController.addUserScript(userScript)
        }

        // 2. Inject swap layout JS
        if let jsPath = Bundle.main.path(forResource: "swapLayout", ofType: "js"),
           let jsContent = try? String(contentsOfFile: jsPath, encoding: .utf8) {
            let userScript = WKUserScript(source: jsContent, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            userContentController.addUserScript(userScript)
        }

        // 3. Inject theme detection script: observe YouTube dark/light mode and notify Swift
        let themeDetectScript = """
        (function() {
            function sendTheme() {
                var isDark = document.documentElement.hasAttribute('dark');
                window.webkit.messageHandlers.themeChanged.postMessage(isDark ? 'dark' : 'light');
            }
            sendTheme();
            var obs = new MutationObserver(function(mutations) {
                for (var m of mutations) {
                    if (m.attributeName === 'dark') { sendTheme(); break; }
                }
            });
            obs.observe(document.documentElement, { attributes: true, attributeFilter: ['dark'] });
        })();
        """
        userContentController.addUserScript(WKUserScript(source: themeDetectScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        userContentController.add(self, name: "themeChanged")

        config.userContentController = userContentController

        // Enable full screen video support
        let preferences = WKPreferences()
        preferences.setValue(true, forKey: "fullScreenEnabled")
        config.preferences = preferences

        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15"
        webView.allowsBackForwardNavigationGestures = true
        webView.uiDelegate = self
        webView.navigationDelegate = self

        window.contentView?.addSubview(webView)

        if let contentView = window.contentView {
            NSLayoutConstraint.activate([
                webView.topAnchor.constraint(equalTo: contentView.topAnchor),
                webView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
                webView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
                webView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
            ])
        }
    }

    // MARK: - WKScriptMessageHandler (Theme Detection)
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == "themeChanged", let theme = message.body as? String {
            DispatchQueue.main.async {
                if theme == "dark" {
                    self.window.backgroundColor = NSColor(red: 15/255, green: 15/255, blue: 15/255, alpha: 1.0)
                } else {
                    self.window.backgroundColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                }
            }
        }
    }

    func loadYouTube() {
        if let url = URL(string: "https://www.youtube.com") {
            var request = URLRequest(url: url)
            request.timeoutInterval = 30
            webView.load(request)
        }
    }

    // MARK: - WKNavigationDelegate (Prevent Universal Link / Safari PWA hijacking)
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            let allowPolicy = WKNavigationActionPolicy(rawValue: WKNavigationActionPolicy.allow.rawValue + 2) ?? .allow
            decisionHandler(allowPolicy)
            return
        }

        // Handle target="_blank" links without targetFrame: keep them in the app
        if navigationAction.targetFrame == nil {
            let host = url.host?.lowercased() ?? ""
            if host.contains("youtube.com") || host.contains("google.com") {
                webView.load(navigationAction.request)
                decisionHandler(.cancel)
                return
            } else {
                NSWorkspace.shared.open(url)
                decisionHandler(.cancel)
                return
            }
        }

        // Bypass macOS Universal Links / Safari Web App (PWA) interception:
        // rawValue: allow.rawValue + 2 forces WebKit to load internally without delegating to external apps
        let allowPolicy = WKNavigationActionPolicy(rawValue: WKNavigationActionPolicy.allow.rawValue + 2) ?? .allow
        decisionHandler(allowPolicy)
    }

    // MARK: - WKUIDelegate (Popups for Google Login / OAuth)
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        // Create popup window with same persistent store
        let popupRect = NSRect(x: 100, y: 100, width: 500, height: 650)
        let popupWindow = NSWindow(
            contentRect: popupRect,
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        popupWindow.title = "Google Sign In"
        popupWindow.center()

        let popupVC = PopupWebViewController()
        popupVC.onLoginFinished = { [weak self] in
            DispatchQueue.main.async {
                self?.webView.reload()
            }
        }
        popupWindow.contentViewController = popupVC
        popupWindows.append(popupWindow)

        NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: popupWindow, queue: .main) { [weak self, weak popupWindow] _ in
            if let target = popupWindow {
                self?.popupWindows.removeAll { $0 == target }
                DispatchQueue.main.async {
                    self?.webView.reload()
                }
            }
        }

        popupWindow.makeKeyAndOrderFront(nil)
        return popupVC.webView
    }

    func webViewDidClose(_ webView: WKWebView) {
        if let win = webView.window, win != self.window {
            win.close()
        }
    }

    // MARK: - Standard macOS Menu (Cmd+C, Cmd+V, Reload, Navigation)
    func setupMenu() {
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

        // 2. File Menu (Close Window)
        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "File")
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
        viewMenu.addItem(withTitle: "Reload", action: #selector(reloadPage), keyEquivalent: "r")
        viewMenu.addItem(withTitle: "Back", action: #selector(goBack), keyEquivalent: "[")
        viewMenu.addItem(withTitle: "Forward", action: #selector(goForward), keyEquivalent: "]")
        viewMenu.addItem(NSMenuItem.separator())
        viewMenu.addItem(withTitle: "Actual Size", action: #selector(zoomActual), keyEquivalent: "0")
        viewMenu.addItem(withTitle: "Zoom In", action: #selector(zoomIn), keyEquivalent: "+")
        viewMenu.addItem(withTitle: "Zoom Out", action: #selector(zoomOut), keyEquivalent: "-")
        viewMenu.addItem(NSMenuItem.separator())
        let fullScreenItem = NSMenuItem(title: "Toggle Full Screen", action: #selector(toggleFullScreen), keyEquivalent: "f")
        fullScreenItem.keyEquivalentModifierMask = [.command, .control]
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

        NSApplication.shared.mainMenu = mainMenu
    }

    @objc func reloadPage() {
        webView.reload()
    }

    @objc func goBack() {
        if webView.canGoBack {
            webView.goBack()
        }
    }

    @objc func goForward() {
        if webView.canGoForward {
            webView.goForward()
        }
    }

    @objc func zoomActual() {
        webView.pageZoom = 1.0
    }

    @objc func zoomIn() {
        webView.pageZoom += 0.1
    }

    @objc func zoomOut() {
        webView.pageZoom = max(0.5, webView.pageZoom - 0.1)
    }

    @objc func toggleFullScreen() {
        window.toggleFullScreen(nil)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
