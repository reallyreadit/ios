import UIKit
import WebKit
import os.log

class ArticleViewController: WebViewUIViewController {
    var hideStatusBar = true
    override var prefersStatusBarHidden: Bool {
        return hideStatusBar
    }
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    var params: ArticleViewControllerParams!
    let speechBubble: SpeechBubbleView
    required init?(coder: NSCoder) {
        // init speech bubble
        speechBubble = SpeechBubbleView(coder: coder)!
        NSLayoutConstraint.activate([
            speechBubble.widthAnchor.constraint(equalToConstant: 32),
            speechBubble.heightAnchor.constraint(equalToConstant: 32)
        ])
        // configure webview
        let config = WKWebViewConfiguration()
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
        super.init(coder: coder, webViewConfig: config)
        webView.customUserAgent = "'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.77 Safari/537.36'"
    }
    override func loadView() {
        view = webView
    }
    override func onMessage(message: (type: String, data: Any?), callbackId: Int?) {
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
        case "registerPage":
            postJson(
                path: "/Extension/GetUserArticle",
                data: ["url": params.article.url.absoluteString],
                onSuccess: {
                    (result: ArticleLookupResult) in
                    self.speechBubble.setState(
                        isLoading: false,
                        percentComplete: result.userArticle.percentComplete,
                        isRead: result.userArticle.isRead
                    )
                    self.sendResponse(data: result.userPage, callbackId: callbackId!)
                },
                onError: { _ in }
            )
        case "commitReadState":
            let event = CommitReadStateEvent(message.data as! [String: Any])
            postJson(
                path: "/Extension/CommitReadState",
                data: event.commitData,
                onSuccess: {
                    (article: UserArticle) in
                    self.speechBubble.setState(
                        isLoading: false,
                        percentComplete: article.percentComplete,
                        isRead: article.isRead
                    )
                    self.params.onReadStateCommitted(
                        ReadStateCommittedEvent(
                            article: article,
                            isCompletionCommit: event.isCompletionCommit
                        )
                    )
                },
                onError: { _ in }
            )
        default:
            return
        }
    }
    func postJson<TData: Encodable, TResult: Decodable>(
        path: String,
        data: TData?,
        onSuccess: @escaping (_: TResult) -> Void,
        onError: @escaping (_: Error?) -> Void
    ) {
        var request = URLRequest(url: URL(string: "http://api.dev.reallyread.it" + path)!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("devSessionKey=\(params.sessionKey)", forHTTPHeaderField: "Cookie")
        request.httpBody = try! JSONEncoder().encode(data)
        URLSession
            .shared
            .dataTask(
                with: request,
                completionHandler: {
                    (data, response, error) in
                    if
                        error == nil,
                        let httpResponse = response as? HTTPURLResponse,
                        (200...299).contains(httpResponse.statusCode),
                        let data = data
                    {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds
                        do {
                            let result = try decoder.decode(TResult.self, from: data)
                            DispatchQueue.main.async {
                                onSuccess(result)
                            }
                        } catch let error {
                            onError(error)
                        }
                    } else {
                        onError(error)
                    }
                }
            )
            .resume()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // speech bubble
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: speechBubble)
        
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
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // show status bar with animation
        hideStatusBar = false
        UIView.animate(withDuration: 0.25) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
        params.onClose()
    }
}
