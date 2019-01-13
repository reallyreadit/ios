import UIKit
import WebKit
import os.log

class ArticleViewController: UIViewController, MessageWebViewDelegate {
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
    private var webView: MessageWebView!
    private var webViewContainer: WebViewContainer!
    required init?(coder: NSCoder) {
        // init speech bubble
        speechBubble = SpeechBubbleView(coder: coder)!
        NSLayoutConstraint.activate([
            speechBubble.widthAnchor.constraint(equalToConstant: 32),
            speechBubble.heightAnchor.constraint(equalToConstant: 32)
        ])
        super.init(coder: coder)
        // init webview
        let config = WKWebViewConfiguration()
        ArticleReading.addContentScript(forConfiguration: config)
        webView = MessageWebView(webViewConfig: config)
        webView.delegate = self
        webView.view.customUserAgent = "'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.77 Safari/537.36'"
        webViewContainer = WebViewContainer(webView: webView.view)
        // configure the error view
        let errorContent = UIView()
        errorContent.translatesAutoresizingMaskIntoConstraints = false
        webViewContainer.errorView.addSubview(errorContent)
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
            errorContent.centerYAnchor.constraint(equalTo: webViewContainer.errorView.centerYAnchor),
            errorContent.topAnchor.constraint(equalTo: errorContent.subviews[0].topAnchor),
            errorContent.bottomAnchor.constraint(equalTo: errorContent.subviews.last!.bottomAnchor),
            errorContent.leadingAnchor.constraint(equalTo: webViewContainer.errorView.leadingAnchor),
            errorContent.trailingAnchor.constraint(equalTo: webViewContainer.errorView.trailingAnchor),
            errorMessage.centerXAnchor.constraint(equalTo: errorContent.centerXAnchor),
            errorMessage.leadingAnchor.constraint(greaterThanOrEqualTo: errorContent.leadingAnchor, constant: 8),
            errorMessage.trailingAnchor.constraint(lessThanOrEqualTo: errorContent.trailingAnchor, constant: 8)
        ])
    }
    override func loadView() {
        view = webViewContainer.view
    }
    func onMessage(message: (type: String, data: Any?), callbackId: Int?) {
        switch message.type {
        case "registerContentScript":
            webView.sendResponse(
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
            APIServer.postJson(
                path: "/Extension/GetUserArticle",
                data: ["url": params.article.url.absoluteString],
                onSuccess: {
                    [weak self] (result: ArticleLookupResult) in
                    if let self = self {
                        DispatchQueue.main.async {
                            self.speechBubble.setState(
                                isLoading: false,
                                percentComplete: result.userArticle.percentComplete,
                                isRead: result.userArticle.isRead
                            )
                            self.webView.sendResponse(data: result.userPage, callbackId: callbackId!)
                        }
                    }
                },
                onError: {
                    [weak self] _ in
                    if let self = self {
                        DispatchQueue.main.async {
                            self.setErrorState(withMessage: "Error loading reading progress.")
                        }
                    }
                }
            )
        case "commitReadState":
            let event = CommitReadStateEvent(message.data as! [String: Any])
            APIServer.postJson(
                path: "/Extension/CommitReadState",
                data: event.commitData,
                onSuccess: {
                    [weak self] (article: UserArticle) in
                    if let self = self {
                        DispatchQueue.main.async {
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
                    }
                },
                onError: {
                    [weak self] _ in
                    if let self = self {
                        DispatchQueue.main.async {
                            self.setErrorState(withMessage: "Error saving reading progress.")
                        }
                    }
                }
            )
        default:
            return
        }
    }
    func setErrorState(withMessage message: String) {
        speechBubble.setState(isLoading: false)
        errorMessage.text = message
        webViewContainer.setState(.error)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // speech bubble
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: speechBubble)
        // fetch and preprocess the article
        ArticleReading.fetchArticle(
            url: params.article.url,
            onSuccess: {
                [weak self] content in
                if let self = self {
                    DispatchQueue.main.async {
                        self.webView.view.loadHTMLString(
                            content as String,
                            baseURL: nil
                        )
                        self.speechBubble.setState(isLoading: true)
                    }
                }
            },
            onError: {
                [weak self] in
                if let self = self {
                    DispatchQueue.main.async {
                        self.setErrorState(withMessage: "Error loading article.")
                    }
                }
            }
        )
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.isBeingDismissed || self.isMovingFromParent {
            // clean up webview
            webView.dispose()
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
