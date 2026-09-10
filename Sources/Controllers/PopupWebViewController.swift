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
