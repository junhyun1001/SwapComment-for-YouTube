import Cocoa
import WebKit

class PopupWebViewController: NSViewController, WKUIDelegate, WKNavigationDelegate {
    var webView: WKWebView!
    var onLoginFinished: (() -> Void)?
    private let configuration: WKWebViewConfiguration
    private var isClosing = false

    init(configuration: WKWebViewConfiguration) {
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        webView = WKWebView(frame: .zero, configuration: configuration)
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
        let finishHandler = onLoginFinished
        onLoginFinished = nil
        DispatchQueue.main.async { [weak self] in
            finishHandler?()
            self?.view.window?.close()
        }
    }
}
