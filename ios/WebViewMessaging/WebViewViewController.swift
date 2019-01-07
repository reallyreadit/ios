import UIKit
import WebKit

class WebViewViewController:
    UIViewController,
    WKHTTPCookieStoreObserver,
    WKScriptMessageHandler,
    WKNavigationDelegate
{
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
    let errorView: UIView = UIView()
    let loadingView: UIView = UIView()
    private let messageHandlerKey = "reallyreadit"
    let overlay = UIView()
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
        // add self as event listener
        config.userContentController.add(self, name: messageHandlerKey)
        config.websiteDataStore.httpCookieStore.add(self)
        // create webview with configuration
        webView = WKWebView(
            frame: .zero,
            configuration: config
        )
        // assign self as navigation delegate
        webView.navigationDelegate = self
        // add overlay
        webView.addSubview(overlay)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            overlay.leadingAnchor.constraint(equalTo: webView.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: webView.trailingAnchor),
            overlay.topAnchor.constraint(equalTo: webView.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: webView.bottomAnchor)
        ])
        // add overlay subviews
        overlay.addSubview(loadingView)
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingView.centerXAnchor.constraint(equalTo: overlay.centerXAnchor),
            loadingView.centerYAnchor.constraint(equalTo: overlay.centerYAnchor)
        ])
        overlay.addSubview(errorView)
        // show loading view
        loadingView.isHidden = false
        errorView.isHidden = true
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
    func webView(_: WKWebView, didFail: WKNavigation!, withError: Error) {
        loadingView.isHidden = true
        errorView.isHidden = false
        overlay.isHidden = false
    }
    func webView(_: WKWebView, didFinish: WKNavigation!) {
        overlay.isHidden = true
        loadingView.isHidden = true
        errorView.isHidden = true
    }
}
