import UIKit
import WebKit
import SafariServices
import os.log
import AuthenticationServices

class ArticleViewController:
    UIViewController,
    MessageWebViewDelegate,
    UIGestureRecognizerDelegate,
    SFSafariViewControllerDelegate,
    ASWebAuthenticationPresentationContextProviding
{
    private let apiServer = APIServerURLSession()
    private var commitErrorCount = 0
    private var hasParsedPage = false
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
    private var webAuthSession: NSObject?
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
            injectedScript: AppBundleInfo.readerScript
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
        apiServer.getJson(
            path: "/Articles/Details",
            queryItems: URLQueryItem(name: "slug", value: slug),
            onSuccess: {
                [weak self] (article: Article) in
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
        ArticleProcessing.fetchArticle(
            url: url,
            mode: .reader,
            onSuccess: {
                [weak self] content in
                if let self = self {
                    DispatchQueue.main.async {
                        self.webView.view.loadHTMLString(
                            content as String,
                            baseURL: (
                                SharedBundleInfo.debugReader ?
                                    url :
                                    URL(
                                        string: url.absoluteString.replacingOccurrences(
                                            of: "^http:",
                                            with: "https:",
                                            options: [.regularExpression, .caseInsensitive]
                                        )
                                    )!
                            )
                        )
                        self.progressBar.setState(isLoading: true)
                    }
                    DispatchQueue.main.asyncAfter(
                        deadline: .now() + .seconds(30),
                        execute: {
                            [weak self] in
                            if
                                let self = self,
                                !self.hasParsedPage
                            {
                                self.setErrorState(withMessage: "Error parsing article.")
                            }
                        }
                    )
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
        case "commitReadState":
            let event = CommitReadStateEvent(message.data as! [String: Any])
            apiServer.postJson(
                path: "/Extension/CommitReadState",
                data: event.commitData,
                onSuccess: {
                    [weak self] (article: Article) in
                    if let self = self {
                        self.commitErrorCount = 0
                        DispatchQueue.main.async {
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
                        if self.commitErrorCount > 5 {
                            DispatchQueue.main.async {
                                self.setErrorState(withMessage: "Error saving reading progress.")
                            }
                        } else {
                            self.commitErrorCount += 1
                        }
                    }
                }
            )
        case "deleteComment":
            apiServer.postJson(
                path: "/Social/CommentDeletion",
                data: CommentDeletionForm(message.data as! [String: Any]),
                onSuccess: {
                    [weak self] (comment: CommentThread) in
                    if let self = self {
                        DispatchQueue.main.async {
                            self.params.onCommentUpdated(comment)
                            self.webView.sendResponse(data: comment, callbackId: callbackId!)
                        }
                    }
                },
                onError: {
                    [weak self] _ in
                    if let self = self {
                        DispatchQueue.main.async {
                            self.setErrorState(withMessage: "Error posting comment addendum.")
                        }
                    }
                }
            )
        case "getComments":
            apiServer.getJson(
                path: "/Social/Comments",
                queryItems: URLQueryItem(name: "slug", value: message.data as? String),
                onSuccess: {
                    [weak self] (comments: [CommentThread]) in
                    if let self = self {
                        DispatchQueue.main.async {
                            self.webView.sendResponse(data: comments, callbackId: callbackId!)
                        }
                    }
                },
                onError: {
                    _ in os_log("error fetching comments")
                }
            )
        case "navTo":
            if let url = URL(string: message.data as! String) {
                params.onNavTo(url)
                navigationController?.popViewController(animated: true)
            }
        case "linkTwitterAccount":
            if let credentials = TwitterCredentialLinkForm(serializedForm: message.data as! [String: Any]) {
                apiServer.postJson(
                    path: "/Auth/TwitterLink",
                    data: credentials,
                    onSuccess: {
                        [weak self] (association: AuthServiceAccountAssociation) in
                        if let self = self {
                            DispatchQueue.main.async {
                                self.params.onAuthServiceAccountLinked(association)
                                self.webView.sendResponse(data: association, callbackId: callbackId!)
                            }
                        }
                    },
                    onError: {
                        [weak self] _ in
                        if let self = self {
                            DispatchQueue.main.async {
                                self.setErrorState(withMessage: "Error linking Twitter account.")
                            }
                        }
                    }
                )
            }
        case "openExternalUrl":
            if let url = URL(string: message.data as! String) {
                presentSafariViewController(url: url, delegate: self)
            }
        case "parseResult":
            hasParsedPage = true
            apiServer.postJson(
                path: "/Extension/GetUserArticle",
                data: PageParseResult(contentScriptData: message.data as! [String: Any]),
                onSuccess: {
                    [weak self] (result: ArticleLookupResult) in
                    if let self = self {
                        DispatchQueue.main.async {
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
            webViewContainer.setState(.loaded)
        case "postArticle":
            apiServer.postJson(
                path: "/Social/Post",
                data: PostForm(message.data as! [String: Any]),
                onSuccess: {
                    [weak self] (post: Post) in
                    if let self = self {
                        DispatchQueue.main.async {
                            self.params.onArticlePosted(post)
                            self.params.onArticleUpdated(
                                ArticleUpdatedEvent(
                                    article: post.article,
                                    isCompletionCommit: false
                                )
                            )
                            if let postComment = post.comment {
                                self.params.onCommentPosted(
                                    CommentThread(
                                        id: postComment.id,
                                        dateCreated: post.date,
                                        text: postComment.text,
                                        addenda: postComment.addenda,
                                        articleId: post.article.id,
                                        articleTitle: post.article.title,
                                        articleSlug: post.article.slug,
                                        userAccount: post.userName,
                                        badge: post.badge,
                                        parentCommentId: nil,
                                        dateDeleted: post.dateDeleted,
                                        children: [],
                                        maxDate: post.date
                                    )
                                )
                            }
                            self.webView.sendResponse(data: post, callbackId: callbackId!)
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
        case "postComment":
            apiServer.postJson(
                path: "/Social/Comment",
                data: CommentForm(message.data as! [String: Any]),
                onSuccess: {
                    [weak self] (result: PostCommentResult) in
                    if let self = self {
                        DispatchQueue.main.async {
                            self.params.onArticleUpdated(
                                ArticleUpdatedEvent(
                                    article: result.article,
                                    isCompletionCommit: false
                                )
                            )
                            self.params.onCommentPosted(result.comment)
                            self.webView.sendResponse(data: result, callbackId: callbackId!)
                        }
                    }
                },
                onError: {
                    [weak self] _ in
                    if let self = self {
                        DispatchQueue.main.async {
                            self.setErrorState(withMessage: "Error posting comment.")
                        }
                    }
                }
            )
        case "postCommentAddendum":
            apiServer.postJson(
                path: "/Social/CommentAddendum",
                data: CommentAddendumForm(message.data as! [String: Any]),
                onSuccess: {
                    [weak self] (comment: CommentThread) in
                    if let self = self {
                        DispatchQueue.main.async {
                            self.params.onCommentUpdated(comment)
                            self.webView.sendResponse(data: comment, callbackId: callbackId!)
                        }
                    }
                },
                onError: {
                    [weak self] _ in
                    if let self = self {
                        DispatchQueue.main.async {
                            self.setErrorState(withMessage: "Error posting comment addendum.")
                        }
                    }
                }
            )
        case "postCommentRevision":
            apiServer.postJson(
                path: "/Social/CommentRevision",
                data: CommentRevisionForm(message.data as! [String: Any]),
                onSuccess: {
                    [weak self] (comment: CommentThread) in
                    if let self = self {
                        DispatchQueue.main.async {
                            self.params.onCommentUpdated(comment)
                            self.webView.sendResponse(data: comment, callbackId: callbackId!)
                        }
                    }
                },
                onError: {
                    [weak self] _ in
                    if let self = self {
                        DispatchQueue.main.async {
                            self.setErrorState(withMessage: "Error posting comment addendum.")
                        }
                    }
                }
            )
        case "readArticle":
            replaceArticle(slug: message.data as! String)
        case "requestTwitterWebViewRequestToken":
            apiServer.postJson(
                path: "/Auth/TwitterWebViewRequest",
                onSuccess: {
                    [weak self] (token: TwitterRequestToken) in
                    if let self = self {
                        DispatchQueue.main.async {
                            self.webView.sendResponse(data: token, callbackId: callbackId!)
                        }
                    }
                },
                onError: {
                    [weak self] _ in
                    if let self = self {
                        DispatchQueue.main.async {
                            self.setErrorState(withMessage: "Error requesting Twitter token.")
                        }
                    }
                }
            )
        case "requestWebAuthentication":
            let request = WebAuthRequest(serializedRequest: message.data as! [String: Any])
            if #available(iOS 13.0, *) {
                let session = ASWebAuthenticationSession(
                    url: request.authURL,
                    callbackURLScheme: request.callbackScheme
                ) {
                    callbackURL, error in
                    DispatchQueue.main.async {
                        self.webView.sendResponse(
                            data: WebAuthResponse(
                                callbackURL: callbackURL,
                                error: error
                            ),
                            callbackId: callbackId!
                        )
                        self.webAuthSession = nil
                    }
                }
                // the session will be deallocated immediately unless we hold on to the reference
                // this workaround is required unless we target iOS >= 13
                webAuthSession = session
                session.presentationContextProvider = self
                session.start()
            } else {
                webView.sendResponse(
                    data: WebAuthResponse(
                        callbackURL: nil,
                        error: "Unsupported"
                    ),
                    callbackId: callbackId!
                )
            }
        case "share":
            presentActivityViewController(
                data: ShareData(message.data as! [String: Any]),
                completionHandler: {
                    result in
                    if let callbackId = callbackId {
                        DispatchQueue.main.async {
                            self.webView.sendResponse(
                                data: result,
                                callbackId: callbackId
                            )
                        }
                    }
                }
            )
        default:
            return
        }
    }
    @available(iOS 13.0, *)
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window!
    }
    func replaceArticle(slug: String) {
        commitErrorCount = 0
        hasParsedPage = false
        progressBar.setState(
            isLoading: false,
            percentComplete: -1,
            isRead: false
        )
        webViewContainer.setState(.loading)
        loadArticle(slug: slug)
    }
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        dismiss(animated: true)
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
