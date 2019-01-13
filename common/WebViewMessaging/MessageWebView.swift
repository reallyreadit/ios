import Foundation

import UIKit
import WebKit

private func jsonEncodeForLiteral<T: Encodable>(_ object: T) -> String {
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
class MessageWebView: NSObject, WKScriptMessageHandler {
    private let messageHandlerKey = "reallyreadit"
    private var responseCallbacks = [ResponseCallback]()
    weak var delegate: MessageWebViewDelegate?
    var view: WKWebView!
    override convenience init() {
        self.init(webViewConfig: WKWebViewConfiguration())
    }
    init(webViewConfig: WKWebViewConfiguration) {
        super.init()
        // add self as webview event listener
        webViewConfig.userContentController.add(self, name: messageHandlerKey)
        // create webview with configuration
        view = WKWebView(
            frame: .zero,
            configuration: webViewConfig
        )
    }
    func dispose() {
        view.configuration.userContentController.removeScriptMessageHandler(
            forName: messageHandlerKey
        )
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
        let envelope = jsonEncodeForLiteral(CallEnvelope(callbackId: callbackId, data: message))
        view.evaluateJavaScript("window.reallyreadit.postMessage('\(envelope)');")
    }
    func sendResponse<T: Codable>(data: T, callbackId: Int) {
        let envelope = jsonEncodeForLiteral(ResponseEnvelope(data: data, id: callbackId))
        view.evaluateJavaScript("window.reallyreadit.sendResponse('\(envelope)');")
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
                delegate?.onMessage(
                    message: (
                        type: message["type"] as! String,
                        data: message["data"]
                    ),
                    callbackId: envelope["callbackId"] as? Int
                )
            }
        }
    }
}
