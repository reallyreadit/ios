import UIKit
import WebKit

class WebViewViewController: UIViewController, WKHTTPCookieStoreObserver, WKScriptMessageHandler {
    private static func jsonEncodeForLiteral<T: Encodable>(_ object: T) -> String {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonString = NSMutableString(
            data: try! encoder.encode(object),
            encoding: String.Encoding.utf8.rawValue
        )!
        jsonString.replaceOccurrences(
            of: "\\",
            with: "\\\\",
            range: NSRange(location: 0, length: jsonString.length)
        )
        jsonString.replaceOccurrences(
            of: "'",
            with: "\\'",
            range: NSRange(location: 0, length: jsonString.length)
        )
        return jsonString as String
    }
    private let messageHandlerKey = "reallyreadit"
    private var responseCallbacks = [ResponseCallback]()
    var webView: WKWebView!
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setWebView(config: WKWebViewConfiguration())
    }
    init?(coder aDecoder: NSCoder, webViewConfig: WKWebViewConfiguration) {
        super.init(coder: aDecoder)
        setWebView(config: webViewConfig)
    }
    private func setWebView(config: WKWebViewConfiguration) {
        config.userContentController.add(self, name: messageHandlerKey)
        config.websiteDataStore.httpCookieStore.add(self)
        webView = WKWebView(
            frame: .zero,
            configuration: config
        )
    }
    func cookiesDidChange(in cookieStore: WKHTTPCookieStore) {
        
    }
    func onMessage(message: (type: String, data: Any?), callbackId: Int?) {
        
    }
    func sendMessage<T: Codable>(message: Message<T>, responseCallback: ((_: Any?) -> Void)? = nil) {
        var callbackId: Int?
        if responseCallback != nil {
            callbackId = (
                responseCallbacks.count > 0 ?
                    responseCallbacks.map({ callback in callback.id }).max()! + 1 :
                    0
            )
            responseCallbacks.append(ResponseCallback(id: callbackId!, function: responseCallback!))
        }
        let envelope = WebViewViewController.jsonEncodeForLiteral(CallEnvelope(callbackId: callbackId, data: message))
        webView.evaluateJavaScript("window.reallyreadit.postMessage('\(envelope)');")
    }
    func sendResponse<T: Codable>(data: T, callbackId: Int) {
        let envelope = WebViewViewController.jsonEncodeForLiteral(ResponseEnvelope(data: data, id: callbackId))
        webView.evaluateJavaScript("window.reallyreadit.sendResponse('\(envelope)');")
    }
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        if
            let envelope = message.body as? [String: Any],
            let message = envelope["data"] as? [String: Any]
        {
            if
                let id = envelope["id"] as? Int,
                let callbackIndex = responseCallbacks.firstIndex(where: { callback in callback.id == id })
            {
                responseCallbacks[callbackIndex].function(message)
                responseCallbacks.remove(at: callbackIndex)
            } else {
                onMessage(
                    message: (
                        type: message["type"] as! String,
                        data: message["data"]
                    ),
                    callbackId: envelope["callbackId"] as? Int
                )
            }
        }
    }
    override func viewDidDisappear(_ animated: Bool) {
        if self.isBeingDismissed || self.isMovingFromParent {
            webView.configuration.userContentController.removeScriptMessageHandler(
                forName: messageHandlerKey
            )
            webView.configuration.websiteDataStore.httpCookieStore.remove(self)
        }
    }
}
