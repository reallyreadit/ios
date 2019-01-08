import UIKit
import WebKit
import os.log

class ArticleViewController: WebViewViewController {
    private static let scripts = [
        ArticleViewControllerScript(
            appSupportFileName: nil,
            bundleFileName: "WebViewMessagingContextAmdModuleShim",
            injectionTime: .atDocumentStart
        ),
        ArticleViewControllerScript(
            appSupportFileName: nil,
            bundleFileName: "WebViewMessagingContext",
            injectionTime: .atDocumentStart
        ),
        ArticleViewControllerScript(
            appSupportFileName: nil,
            bundleFileName: "ContentScriptMessagingShim",
            injectionTime: .atDocumentStart
        ),
        ArticleViewControllerScript(
            appSupportFileName: "ContentScript.js",
            bundleFileName: "ContentScript",
            injectionTime: .atDocumentEnd
        )
    ]
    private static func postJson<TData: Encodable, TResult: Decodable>(
        path: String,
        data: TData?,
        sessionKey: String,
        onSuccess: @escaping (_: TResult) -> Void,
        onError: @escaping (_: Error?) -> Void
    ) {
        var request = URLRequest(
            url: URL(
                string: (Bundle.main.infoDictionary!["RRITAPIServerURL"] as! String)
                    .trimmingCharacters(in: ["/"]) + path
            )!
        )
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue(
            "\(Bundle.main.infoDictionary!["RRITAuthCookieName"] as! String)=\(sessionKey)",
            forHTTPHeaderField: "Cookie"
        )
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
    // status bar config
    private var hideStatusBar = true
    override var prefersStatusBarHidden: Bool {
        return hideStatusBar
    }
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    var params: ArticleViewControllerParams!
    private let errorMessage = UILabel()
    private let speechBubble: SpeechBubbleView
    required init?(coder: NSCoder) {
        // init speech bubble
        speechBubble = SpeechBubbleView(coder: coder)!
        NSLayoutConstraint.activate([
            speechBubble.widthAnchor.constraint(equalToConstant: 32),
            speechBubble.heightAnchor.constraint(equalToConstant: 32)
        ])
        // configure webview
        let config = WKWebViewConfiguration()
        ArticleViewController.scripts.forEach({
            script in
            var source: String?
            if
                script.appSupportFileName != nil,
                let appSupportDirURL = FileManager.default
                    .urls(
                        for: .applicationSupportDirectory,
                        in: .userDomainMask
                    )
                    .first,
                let fileContent = try? String(
                    contentsOf: appSupportDirURL.appendingPathComponent("reallyreadit/\(script.appSupportFileName!)")
                )
            {
                os_log(.debug, "ArticleViewController(coder:): loading script from file: %s", script.bundleFileName)
                source = fileContent
            } else if
                let fileContent = try? String(
                    contentsOf: Bundle.main.url(forResource: script.bundleFileName, withExtension: "js")!
                )
            {
                os_log(.debug, "ArticleViewController(coder:): loading script from bundle: %s", script.bundleFileName)
                source = fileContent
            }
            if source != nil {
                config.userContentController.addUserScript(
                    WKUserScript(
                        source: source!,
                        injectionTime: script.injectionTime,
                        forMainFrameOnly: true
                    )
                )
            } else {
                os_log(.debug, "ArticleViewController(coder:): error loading script: %s", script.bundleFileName)
            }
        })
        // init super to create webview
        super.init(coder: coder, webViewConfig: config)
        // configure instance
        webView.customUserAgent = "'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.77 Safari/537.36'"
        // configure the error view
        let errorContent = UIView()
        errorContent.translatesAutoresizingMaskIntoConstraints = false
        errorView.addSubview(errorContent)
        errorMessage.numberOfLines = 0
        errorMessage.textAlignment = .center
        errorMessage.translatesAutoresizingMaskIntoConstraints = false
        errorContent.addSubview(errorMessage)
        [
            "Check your internet connection and try again.",
            "Please contact support@reallyread.it if this problem persists."
        ]
        .forEach({
            line in
            let label = UILabel()
            label.text = line
            label.numberOfLines = 0
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            errorContent.addSubview(label)
            NSLayoutConstraint.activate([
                label.centerXAnchor.constraint(equalTo: errorContent.centerXAnchor),
                label.topAnchor.constraint(
                    equalTo: errorContent.subviews[errorContent.subviews.count - 2].bottomAnchor,
                    constant: 8
                ),
                label.leadingAnchor.constraint(greaterThanOrEqualTo: errorContent.leadingAnchor, constant: 8),
                label.trailingAnchor.constraint(lessThanOrEqualTo: errorContent.trailingAnchor, constant: 8)
            ])
        })
        NSLayoutConstraint.activate([
            errorContent.centerYAnchor.constraint(equalTo: errorView.centerYAnchor),
            errorContent.topAnchor.constraint(equalTo: errorContent.subviews[0].topAnchor),
            errorContent.bottomAnchor.constraint(equalTo: errorContent.subviews.last!.bottomAnchor),
            errorContent.leadingAnchor.constraint(equalTo: errorView.leadingAnchor),
            errorContent.trailingAnchor.constraint(equalTo: errorView.trailingAnchor),
            errorMessage.centerXAnchor.constraint(equalTo: errorContent.centerXAnchor),
            errorMessage.leadingAnchor.constraint(greaterThanOrEqualTo: errorContent.leadingAnchor, constant: 8),
            errorMessage.trailingAnchor.constraint(lessThanOrEqualTo: errorContent.trailingAnchor, constant: 8)
        ])
    }
    override func loadView() {
        view = webViewContainer
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
                    showOverlay: Bundle.main.infoDictionary!["RRITDebugReader"] as! Bool,
                    sourceRules: []
                ),
                callbackId: callbackId!
            )
        case "registerPage":
            ArticleViewController.postJson(
                path: "/Extension/GetUserArticle",
                data: ["url": params.article.url.absoluteString],
                sessionKey: params.sessionKey,
                onSuccess: {
                    [weak self] (result: ArticleLookupResult) in
                    if let self = self {
                        self.speechBubble.setState(
                            isLoading: false,
                            percentComplete: result.userArticle.percentComplete,
                            isRead: result.userArticle.isRead
                        )
                        self.sendResponse(data: result.userPage, callbackId: callbackId!)
                    }
                },
                onError: {
                    [weak self] _ in
                    self?.setErrorState(withMessage: "Error loading reading progress.")
                }
            )
        case "commitReadState":
            let event = CommitReadStateEvent(message.data as! [String: Any])
            ArticleViewController.postJson(
                path: "/Extension/CommitReadState",
                data: event.commitData,
                sessionKey: params.sessionKey,
                onSuccess: {
                    [weak self] (article: UserArticle) in
                    if let self = self {
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
                    }
                },
                onError: {
                    [weak self] _ in
                    self?.setErrorState(withMessage: "Error saving reading progress.")
                }
            )
        default:
            return
        }
    }
    func setErrorState(withMessage message: String) {
        speechBubble.setState(isLoading: false)
        errorMessage.text = message
        super.setState(.error)
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
                    [weak self] (data, response, error) in
                    if
                        let self = self,
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
                            self.speechBubble.setState(isLoading: true)
                        }
                    } else {
                        self?.setErrorState(withMessage: "Error loading article.")
                    }
                }
            )
            .resume()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.isBeingDismissed || self.isMovingFromParent {
            // show status bar with animation
            hideStatusBar = false
            UIView.animate(withDuration: 0.25) {
                self.setNeedsStatusBarAppearanceUpdate()
            }
            // call onClose
            params.onClose()
        }
    }
}
