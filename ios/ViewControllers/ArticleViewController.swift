import UIKit
import WebKit
import os.log

class ArticleViewController: UIViewController, WKScriptMessageHandler {
    // coder
    let coder: NSCoder
    
    // article parameters passed from WebAppViewController
    var params: ArticleViewControllerParams!
    
    // article webview
    var webView: WKWebView!
    
    // init
    required init?(coder: NSCoder) {
        self.coder = coder
        super.init(coder: coder)
    }
    
    // create and configure the webview
    override func loadView() {
        let config = WKWebViewConfiguration()
        config.userContentController = WKUserContentController()
        config.userContentController.add(self, name: "reallyreadit")
        [
            (
                fileName: "WebViewMessagingContextAmdModuleShim",
                injectionTime: WKUserScriptInjectionTime.atDocumentStart
            ), (
                fileName: "WebViewMessagingContext",
                injectionTime: WKUserScriptInjectionTime.atDocumentStart
            ), (
                fileName: "ContentScriptMessagingShim",
                injectionTime: WKUserScriptInjectionTime.atDocumentStart
            ), (
                fileName: "ContentScript",
                injectionTime: WKUserScriptInjectionTime.atDocumentEnd
            )
        ]
        .forEach({
            script in
            config.userContentController.addUserScript(
                WKUserScript(
                    source: try! String(
                        contentsOf: Bundle.main.url(forResource: script.fileName, withExtension: "js")!
                    ),
                    injectionTime: script.injectionTime,
                    forMainFrameOnly: true
                )
            )
        })
        webView = WKWebView(
            frame: .zero,
            configuration: config
        )
        webView.customUserAgent = "'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.77 Safari/537.36'"
        view = webView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // speech bubble
        let bubble = SpeechBubbleView(coder: coder)!
        bubble.widthAnchor.constraint(equalToConstant: 32).isActive = true
        bubble.heightAnchor.constraint(equalToConstant: 32).isActive = true
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: bubble)
        
        // fetch and preprocess the article
        URLSession
            .shared
            .dataTask(
                with: URL(
                    string: params.article.url.absoluteString.replacingOccurrences(
                        of: "^http:",
                        with: "https:",
                        options: [.regularExpression, .caseInsensitive]
                    )
                )!,
                completionHandler: {
                    (data, response, error) in
                    if
                        error == nil,
                        let httpResponse = response as? HTTPURLResponse,
                        (200...299).contains(httpResponse.statusCode),
                        let stringData = NSMutableString(data: data!, encoding: String.Encoding.utf8.rawValue)
                    {
                        
                        [
                            (searchValue: "<script\\b[^<]*(?:(?!</script>)<[^<]*)*</script>", replaceValue: ""),
                            (searchValue: "<iframe\\b[^<]*(?:(?!</iframe>)<[^<]*)*</iframe>", replaceValue: ""),
                            (searchValue: "<meta([^>]*)name=(['\"])viewport\\2([^>]*)>", replaceValue: "<meta name=\"viewport\" content=\"width=device-width,initial-scale=1,user-scalable=no\">"),
                            (searchValue: "<img\\s([^>]*)>", replaceValue: "<img data-rrit-base-url='\(self.params.article.url.absoluteString)' $1>"),
                            (searchValue: "<img([^>]*)\\ssrc=(['\"])((?:(?!\\2).)*)\\2([^>]*)>", replaceValue: "<img$1 data-rrit-src=$2$3$2$4>"),
                            (searchValue: "<img([^>]*)\\ssrcset=(['\"])((?:(?!\\2).)*)\\2([^>]*)>", replaceValue: "<img$1 data-rrit-srcset=$2$3$2$4>")
                        ]
                        .forEach({ replacement in
                            stringData.replaceOccurrences(
                                of: replacement.searchValue,
                                with: replacement.replaceValue,
                                options: [.regularExpression, .caseInsensitive],
                                range: NSRange(location: 0, length: stringData.length)
                            )
                        })
                        DispatchQueue.main.async {
                            self.webView.loadHTMLString(
                                stringData as String,
                                baseURL: nil
                            )
                        }
                    } else {
                        os_log(.debug, "Error loading article")
                    }
                }
            )
            .resume()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController!.setNavigationBarHidden(false, animated: true)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController!.setNavigationBarHidden(true, animated: true)
    }
    
    // messaging
    struct Message<T: Codable>: Codable {
        let type: String
        let data: T
    }
    struct CallEnvelope<T: Codable>: Codable {
        let callbackId: Int?
        let data: T
    }
    struct ResponseEnvelope<T: Codable>: Codable {
        let data: T
        let id: Int
    }
    struct ResponseCallback {
        let id: Int
        let function: (_: Any?) -> Void
    }
    var responseCallbacks = [ResponseCallback]()
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
    func jsonEncodeForLiteral<T: Encodable>(_ object: T) -> String {
        let jsonString = NSMutableString(
            data: try! JSONEncoder().encode(object),
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
    func sendMessage<T: Codable>(message: Message<T>, responseCallback: ((_: Any?) -> Void)?) {
        var callbackId: Int?
        if responseCallback != nil {
            callbackId = (
                responseCallbacks.count > 0 ?
                    responseCallbacks.map({ callback in callback.id }).max()! + 1 :
                    0
            )
            responseCallbacks.append(ResponseCallback(id: callbackId!, function: responseCallback!))
        }
        let envelope = self.jsonEncodeForLiteral(CallEnvelope(callbackId: callbackId, data: message))
        webView.evaluateJavaScript(
            "window.reallyreadit.postMessage('\(envelope)');"
        )
    }
    func sendResponse<T: Codable>(data: T, callbackId: Int) {
        let envelope = self.jsonEncodeForLiteral(ResponseEnvelope(data: data, id: callbackId))
        webView.evaluateJavaScript(
            "window.reallyreadit.sendResponse('\(envelope)');"
        )
    }
    func onMessage(message: (type: String, data: Any?), callbackId: Int?) {
        switch message.type {
        case "registerContentScript":
            sendResponse(
                data: ContentScriptInitData(
                    config: ContentScriptConfig(
                        idleReadRate: 500,
                        pageOffsetUpdateRate: 3000,
                        readStateCommitRate: 3000,
                        readWordRate: 100
                    ),
                    loadPage: true,
                    parseMetadata: false,
                    parseMode: "mutate",
                    showOverlay: false,
                    sourceRules: []
                ),
                callbackId: callbackId!
            )
        default:
            return
        }
    }
}
