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
    private let messageHandlerKey = "reallyreadit"
    private var responseCallbacks = [ResponseCallback]()
    let errorView: UIView = UIView()
    let loadingView: UIView = UIView()
    var state: WebViewState!
    var webView: WKWebView!
    let webViewContainer = UIView()
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize(config: WKWebViewConfiguration())
    }
    init?(coder aDecoder: NSCoder, webViewConfig: WKWebViewConfiguration) {
        super.init(coder: aDecoder)
        initialize(config: webViewConfig)
    }
    private func initialize(config: WKWebViewConfiguration) {
        // add self as webview event listener
        config.userContentController.add(self, name: messageHandlerKey)
        config.websiteDataStore.httpCookieStore.add(self)
        // create webview with configuration
        webView = WKWebView(
            frame: .zero,
            configuration: config
        )
        // assign self as navigation delegate
        webView.navigationDelegate = self
        // add webview to container
        webViewContainer.addSubview(webView)
        webView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: webViewContainer.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: webViewContainer.trailingAnchor),
            webView.topAnchor.constraint(equalTo: webViewContainer.topAnchor),
            webView.bottomAnchor.constraint(equalTo: webViewContainer.bottomAnchor)
        ])
        // configure the loading view
        let indicator = UIActivityIndicatorView()
        indicator.color = .gray
        indicator.startAnimating()
        loadingView.addSubview(indicator)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: loadingView.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: loadingView.centerYAnchor)
        ])
        // add loading view to container
        loadingView.backgroundColor = .white
        webViewContainer.addSubview(loadingView)
        loadingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            loadingView.leadingAnchor.constraint(equalTo: webViewContainer.leadingAnchor),
            loadingView.trailingAnchor.constraint(equalTo: webViewContainer.trailingAnchor),
            loadingView.topAnchor.constraint(equalTo: webViewContainer.topAnchor),
            loadingView.bottomAnchor.constraint(equalTo: webViewContainer.bottomAnchor)
        ])
        // add error view to container
        errorView.backgroundColor = .white
        webViewContainer.addSubview(errorView)
        errorView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            errorView.leadingAnchor.constraint(equalTo: webViewContainer.leadingAnchor),
            errorView.trailingAnchor.constraint(equalTo: webViewContainer.trailingAnchor),
            errorView.topAnchor.constraint(equalTo: webViewContainer.topAnchor),
            errorView.bottomAnchor.constraint(equalTo: webViewContainer.bottomAnchor)
        ])
        // set loading state
        setState(.loading)
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
    func setState(_ state: WebViewState) {
        self.state = state
        switch state {
        case .error:
            loadingView.isHidden = true
            errorView.isHidden = false
        case .loaded:
            loadingView.isHidden = true
            errorView.isHidden = true
        case .loading:
            loadingView.isHidden = false
            errorView.isHidden = true
        }
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
        setState(.error)
    }
    func webView(_: WKWebView, didFailProvisionalNavigation: WKNavigation!, withError: Error) {
        setState(.error)
    }
    func webView(_: WKWebView, didFinish: WKNavigation!) {
        setState(.loaded)
    }
    func webView(_: WKWebView, didStartProvisionalNavigation: WKNavigation!) {
        setState(.loading)
    }
}
