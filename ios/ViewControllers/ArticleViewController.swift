import UIKit
import WebKit
import os.log

class ArticleViewController: UIViewController, MessageWebViewDelegate, UIGestureRecognizerDelegate {
    private var article: UserArticle!
    private var articleURL: URL!
    private var hideStatusBar = false
    override var prefersStatusBarHidden: Bool {
        return hideStatusBar
    }
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    var params: ArticleViewControllerParams!
    private let errorMessage = UILabel()
    private let progressBar: ProgressBarView
    private var webView: MessageWebView!
    private var webViewContainer: WebViewContainer!
    required init?(coder: NSCoder) {
        // init speech bubble
        progressBar = ProgressBarView(coder: coder)!
        NSLayoutConstraint.activate([
            progressBar.widthAnchor.constraint(equalToConstant: 32),
            progressBar.heightAnchor.constraint(equalToConstant: 32)
        ])
        super.init(coder: coder)
        // init webview
        let config = WKWebViewConfiguration()
        webView = MessageWebView(
            webViewConfig: config,
            javascriptListenerObject: "window.reallyreadit.nativeClient.reader",
            injectedScriptName: "reader"
        )
        webView.delegate = self
        webView.view.customUserAgent = "'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.77 Safari/537.36'"
        let panGestureRecognizer = UIPanGestureRecognizer(
            target: self,
            action: #selector(handlePanGesture(_:))
        )
        panGestureRecognizer.delegate = self
        webView.view.addGestureRecognizer(panGestureRecognizer)
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
            "Please contact support@readup.com if this problem persists."
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
    @objc private func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        let panYTranslation = sender.translation(in: sender.view).y
        if panYTranslation < 0 && !hideStatusBar {
            setBarsVisibility(hidden: true)
        } else if hideStatusBar && (
            panYTranslation > 300 ||
            (
                panYTranslation > 50 &&
                sender.velocity(in: sender.view).y > 500
            )
        ) {
            setBarsVisibility(hidden: false)
        }
    }
    private func loadArticle(slug: String) {
        APIServer.getJson(
            path: "/Articles/Details",
            queryItems: URLQueryItem(name: "slug", value: slug),
            onSuccess: {
                [weak self] (article: UserArticle) in
                if let self = self {
                    self.loadArticle(url: URL(string: article.url)!)
                }
            },
            onError: {
                [weak self] _ in
                if let self = self {
                    DispatchQueue.main.async {
                        self.setErrorState(withMessage: "Error looking up article.")
                    }
                }
            }
        )
    }
    private func loadArticle(url: URL) {
        articleURL = url
        ArticleProcessing.fetchArticle(
            url: url,
            onSuccess: {
                [weak self] content in
                if let self = self {
                    DispatchQueue.main.async {
                        self.webView.view.loadHTMLString(
                            content as String,
                            baseURL: self.articleURL
                        )
                        self.progressBar.setState(isLoading: true)
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
    private func setBarsVisibility(hidden: Bool) {
        hideStatusBar = hidden
        navigationController!.setNavigationBarHidden(hidden, animated: true)
        UIView.animate(withDuration: 0.25) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        return true
    }
    override func loadView() {
        view = webViewContainer.view
    }
    func onMessage(message: (type: String, data: Any?), callbackId: Int?) {
        switch message.type {
        case "parseResult":
            APIServer.postJson(
                path: "/Extension/GetUserArticle",
                data: PageParseResult(contentScriptData: message.data as! [String: Any]),
                onSuccess: {
                    [weak self] (result: ArticleLookupResult) in
                    if let self = self {
                        DispatchQueue.main.async {
                            self.article = result.userArticle
                            self.progressBar.setState(
                                isLoading: false,
                                percentComplete: result.userArticle.percentComplete,
                                isRead: result.userArticle.isRead
                            )
                            self.webView.sendResponse(data: result, callbackId: callbackId!)
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
                            self.article = article
                            self.progressBar.setState(
                                isLoading: false,
                                percentComplete: article.percentComplete,
                                isRead: article.isRead
                            )
                            self.params.onArticleUpdated(
                                ArticleUpdatedEvent(
                                    article: article,
                                    isCompletionCommit: event.isCompletionCommit
                                )
                            )
                            self.webView.sendResponse(data: article, callbackId: callbackId!)
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
        case "rateArticle":
            APIServer.postJson(
                path: "/Articles/Rate",
                data: ArticleRatingForm(message.data as! [String: Any]),
                onSuccess: {
                    [weak self] (rating: Rating) in
                    if let self = self {
                        DispatchQueue.main.async {
                            self.article.ratingScore = rating.score
                            self.params.onArticleUpdated(
                                ArticleUpdatedEvent(
                                    article: self.article,
                                    isCompletionCommit: false
                                )
                            )
                            self.webView.sendResponse(data: rating, callbackId: callbackId!)
                        }
                    }
                },
                onError: {
                    [weak self] _ in
                    if let self = self {
                        DispatchQueue.main.async {
                            self.setErrorState(withMessage: "Error rating article.")
                        }
                    }
                }
            )
        default:
            return
        }
    }
    func replaceArticle(slug: String) {
        article = nil
        articleURL = nil
        progressBar.setState(
            isLoading: false,
            percentComplete: -1,
            isRead: false
        )
        webViewContainer.setState(.loading)
        loadArticle(slug: slug)
    }
    func setErrorState(withMessage message: String) {
        progressBar.setState(isLoading: false)
        errorMessage.text = message
        webViewContainer.setState(.error)
        setBarsVisibility(hidden: false)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // speech bubble
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: progressBar)
        // fetch and preprocess the article
        switch params.articleReference {
        case .slug(let slug):
            loadArticle(slug: slug)
        case .url(let url):
            loadArticle(url: url)
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.isBeingDismissed || self.isMovingFromParent {
            // clean up webview
            webView.dispose()
            // show status bar with animation
            if hideStatusBar {
                hideStatusBar = false
                UIView.animate(withDuration: 0.25) {
                    self.setNeedsStatusBarAppearanceUpdate()
                }
            }
            // call onClose
            params.onClose()
        }
    }
}
