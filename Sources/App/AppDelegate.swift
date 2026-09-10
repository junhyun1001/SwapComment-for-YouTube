import Cocoa
import WebKit

class AppDelegate: NSObject, NSApplicationDelegate, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler, ViewMenuActionDelegate {
    var window: NSWindow!
    var windowController: MainWindowController!
    var webView: WKWebView!
    var popupWindows: [NSWindow] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.mainMenu = MenuBuilder.build(target: self)
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
        WebScriptManager.configure(userContentController: userContentController, handler: self)
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
        if message.name == WebScriptManager.themeChangedMessageName, let theme = message.body as? String {
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

    // MARK: - ViewMenuActionDelegate
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
