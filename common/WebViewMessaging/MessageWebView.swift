import Foundation
import UIKit
import WebKit
import os.log

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
    private let javascriptListenerObject: String
    private let messageHandlerKey = "reallyreadit"
    private var responseCallbacks = [ResponseCallback]()
    weak var delegate: MessageWebViewDelegate?
    var view: WKWebView!
    init(
        webViewConfig: WKWebViewConfiguration,
        javascriptListenerObject: String,
        injectedScript: WebViewScript? = nil
    ) {
        self.javascriptListenerObject = javascriptListenerObject
        super.init()
        // add self as webview event listener
        webViewConfig.userContentController.add(self, name: messageHandlerKey)
        // configure injected script
        if let injectedScript = injectedScript {
            var scriptSource: String?
            if
                let downloadedFileVersion = LocalStorage.getVersionForScript(name: injectedScript.name),
                downloadedFileVersion.compareTo(injectedScript.bundledVersion) > 0,
                let containerURL = FileManager.default.containerURL(
                    forSecurityApplicationGroupIdentifier: "group.it.reallyread"
                ),
                let fileContent = try? String(
                    contentsOf: containerURL.appendingPathComponent(injectedScript.name + ".js")
                )
            {
                os_log("[webview-msg] loading script from file: %s", injectedScript.name)
                scriptSource = fileContent
            } else if
                let fileContent = try? String(
                    contentsOf: Bundle.main.url(forResource: injectedScript.name, withExtension: "js")!
                )
            {
                os_log("[webview-msg] loading script from bundle: %s", injectedScript.name)
                scriptSource = fileContent
            }
            if scriptSource != nil {
                webViewConfig.userContentController.addUserScript(
                    WKUserScript(
                        source: scriptSource!,
                        injectionTime: .atDocumentEnd,
                        forMainFrameOnly: true
                    )
                )
            } else {
                os_log("[webview-msg] error loading script: %s", injectedScript.name)
            }
        }
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
        os_log("[webview-msg] sending message: %s", message.type)
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
        view.evaluateJavaScript("\(javascriptListenerObject).postMessage('\(envelope)');")
    }
    func sendResponse<T: Codable>(data: T, callbackId: Int) {
        os_log("[webview-msg] sending response for callback: %d", callbackId)
        let envelope = jsonEncodeForLiteral(ResponseEnvelope(data: data, id: callbackId))
        view.evaluateJavaScript("\(javascriptListenerObject).sendResponse('\(envelope)');")
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
                os_log("[webview-msg] received response for callback: %d", id)
                responseCallbacks[callbackIndex].function(message)
                responseCallbacks.remove(at: callbackIndex)
            } else {
                let delegateMessage = (
                    type: message["type"] as! String,
                    data: message["data"]
                )
                os_log("[webview-msg] received message: %s", delegateMessage.type)
                delegate?.onMessage(
                    message: delegateMessage,
                    callbackId: envelope["callbackId"] as? Int
                )
            }
        }
    }
}
