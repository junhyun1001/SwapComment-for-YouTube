import Cocoa
import WebKit

class MainViewController: NSViewController, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler, ViewMenuActionDelegate {
    var webView: WKWebView!
    var popupWindows: [NSWindow] = []

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

        webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Safari/605.1.15"
        webView.allowsBackForwardNavigationGestures = true
        webView.uiDelegate = self
        webView.navigationDelegate = self

        self.view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadYouTube()
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
        view.window?.toggleFullScreen(nil)
    }
}
