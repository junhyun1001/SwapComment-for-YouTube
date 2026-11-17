import Foundation
import WebKit

private final class WeakScriptMessageHandler: NSObject, WKScriptMessageHandler {
    private weak var delegate: WKScriptMessageHandler?

    init(delegate: WKScriptMessageHandler) {
        self.delegate = delegate
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        delegate?.userContentController(userContentController, didReceive: message)
    }
}

final class WebScriptManager {
    static let themeChangedMessageName = "themeChanged"

    static func configure(userContentController: WKUserContentController, handler: WKScriptMessageHandler) {
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
        userContentController.add(WeakScriptMessageHandler(delegate: handler), name: themeChangedMessageName)
    }

    static func cleanup(userContentController: WKUserContentController) {
        userContentController.removeScriptMessageHandler(forName: themeChangedMessageName)
    }
}
