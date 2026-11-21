import Cocoa
import WebKit

class MainViewController: NSViewController, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler, ViewMenuActionDelegate {
    private static let pageZoomDefaultsKey = "savedPageZoom"
    var webView: WKWebView!
    var popupWindows: [NSWindow] = []
    private var popupWindowObservers: [ObjectIdentifier: NSObjectProtocol] = [:]
    private var lastWebContentCrashDate: Date?
    private var savedZoomLevel: CGFloat = 1.0

    deinit {
        for token in popupWindowObservers.values {
            NotificationCenter.default.removeObserver(token)
        }
        if isViewLoaded {
            webView.stopLoading()
            WebScriptManager.cleanup(userContentController: webView.configuration.userContentController)
        }
    }

    override func loadView() {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default()
        config.allowsAirPlayForMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []

        let userContentController = WKUserContentController()
        WebScriptManager.configure(userContentController: userContentController, handler: self)
        config.userContentController = userContentController

        let preferences = WKPreferences()
        preferences.setValue(true, forKey: "fullScreenEnabled")
        config.preferences = preferences

        let containerView = NSView(frame: .zero)
        containerView.autoresizingMask = [.width, .height]

        webView = WKWebView(frame: .zero, configuration: config)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15"
        webView.allowsBackForwardNavigationGestures = true
        webView.uiDelegate = self
        webView.navigationDelegate = self

        let storedZoom = UserDefaults.standard.double(forKey: Self.pageZoomDefaultsKey)
        if storedZoom >= 0.5 && storedZoom <= 3.0 {
            savedZoomLevel = CGFloat(storedZoom)
        }

        containerView.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            webView.topAnchor.constraint(equalTo: containerView.topAnchor),
            webView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])

        self.view = containerView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadYouTube()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        if webView.pageZoom != savedZoomLevel {
            webView.pageZoom = savedZoomLevel
        }
        webView.needsLayout = true
    }

    override func viewDidLayout() {
        super.viewDidLayout()
        webView?.needsLayout = true
    }

    func syncLayoutAfterResize() {
        guard isViewLoaded else { return }
        view.layoutSubtreeIfNeeded()
        webView.needsLayout = true
        webView.evaluateJavaScript("window.dispatchEvent(new Event('resize'));", completionHandler: nil)
    }

    func loadYouTube() {
        if let url = URL(string: "https://www.youtube.com") {
            var request = URLRequest(url: url)
            request.timeoutInterval = 30
            webView.load(request)
        }
    }

    // MARK: - WKScriptMessageHandler (Theme Detection)
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if message.name == WebScriptManager.themeChangedMessageName, let theme = message.body as? String {
            DispatchQueue.main.async { [weak self] in
                if theme == "dark" {
                    self?.view.window?.backgroundColor = NSColor(red: 15/255, green: 15/255, blue: 15/255, alpha: 1.0)
                } else {
                    self?.view.window?.backgroundColor = NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
                }
            }
        }
    }

    // MARK: - Link Helpers
    private func extractYouTubeRedirectTarget(from url: URL) -> URL? {
        let host = url.host?.lowercased() ?? ""
        guard (host == "youtube.com" || host.hasSuffix(".youtube.com")),
              url.path == "/redirect",
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let rawTarget = components.queryItems?.first(where: { $0.name == "q" })?.value,
              let targetURL = URL(string: rawTarget),
              let scheme = targetURL.scheme?.lowercased(),
              scheme == "http" || scheme == "https" else {
            return nil
        }
        return targetURL
    }

    private func isInAppHost(_ host: String) -> Bool {
        return host == "youtube.com"
            || host.hasSuffix(".youtube.com")
            || host == "youtu.be"
            || host == "google.com"
            || host.hasSuffix(".google.com")
    }

    private func isExternalOpenableURL(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https" || scheme == "mailto"
    }

    // MARK: - WKNavigationDelegate (Prevent Universal Link / Safari PWA hijacking)
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        let allowPolicy = WKNavigationActionPolicy(rawValue: WKNavigationActionPolicy.allow.rawValue + 2) ?? .allow

        guard let url = navigationAction.request.url else {
            decisionHandler(allowPolicy)
            return
        }

        if let redirectTarget = extractYouTubeRedirectTarget(from: url) {
            NSWorkspace.shared.open(redirectTarget)
            decisionHandler(.cancel)
            return
        }

        // Handle target="_blank" links without targetFrame: keep YouTube/Google in app, open external URLs in default browser
        if navigationAction.targetFrame == nil {
            let host = url.host?.lowercased() ?? ""
            if isInAppHost(host) {
                webView.load(navigationAction.request)
            } else if isExternalOpenableURL(url) {
                NSWorkspace.shared.open(url)
            }
            decisionHandler(.cancel)
            return
        }

        // Bypass macOS Universal Links / Safari Web App (PWA) interception:
        decisionHandler(allowPolicy)
    }

    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        let now = Date()
        if let lastCrash = lastWebContentCrashDate, now.timeIntervalSince(lastCrash) < 10 {
            return
        }
        lastWebContentCrashDate = now
        webView.reload()
    }

    // MARK: - WKUIDelegate (Popups for Google Login / OAuth)
    func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url {
            if let redirectTarget = extractYouTubeRedirectTarget(from: url) {
                NSWorkspace.shared.open(redirectTarget)
                return nil
            }
            let host = url.host?.lowercased() ?? ""
            if !host.isEmpty && !isInAppHost(host) && isExternalOpenableURL(url) {
                NSWorkspace.shared.open(url)
                return nil
            }
        }

        let popupRect = NSRect(x: 100, y: 100, width: 500, height: 650)
        let popupWindow = NSWindow(
            contentRect: popupRect,
            styleMask: [.titled, .closable, .resizable],
            backing: .buffered,
            defer: false
        )
        popupWindow.title = "Google Sign In"
        popupWindow.isReleasedWhenClosed = false
        popupWindow.center()

        let popupVC = PopupWebViewController(configuration: configuration)
        popupVC.onLoginFinished = { [weak self] in
            DispatchQueue.main.async {
                self?.webView.reload()
            }
        }
        popupWindow.contentViewController = popupVC
        _ = popupVC.view
        popupWindows.append(popupWindow)

        let windowKey = ObjectIdentifier(popupWindow)
        let observer = NotificationCenter.default.addObserver(forName: NSWindow.willCloseNotification, object: popupWindow, queue: .main) { [weak self, weak popupWindow] _ in
            if let token = self?.popupWindowObservers.removeValue(forKey: windowKey) {
                NotificationCenter.default.removeObserver(token)
            }
            if let target = popupWindow {
                self?.popupWindows.removeAll { $0 === target }
            }
        }
        popupWindowObservers[windowKey] = observer

        popupWindow.makeKeyAndOrderFront(nil)
        return popupVC.webView
    }

    func webViewDidClose(_ webView: WKWebView) {
        if let win = webView.window, win != self.view.window {
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

    private func savePageZoom() {
        savedZoomLevel = webView.pageZoom
        UserDefaults.standard.set(Double(savedZoomLevel), forKey: Self.pageZoomDefaultsKey)
    }

    @objc func zoomActual() {
        webView.pageZoom = 1.0
        savePageZoom()
    }

    @objc func zoomIn() {
        webView.pageZoom = min(3.0, webView.pageZoom + 0.1)
        savePageZoom()
    }

    @objc func zoomOut() {
        webView.pageZoom = max(0.5, webView.pageZoom - 0.1)
        savePageZoom()
    }

    @objc func toggleFullScreen() {
        view.window?.toggleFullScreen(nil)
    }
}
