// Copyright (C) 2022 reallyread.it, inc.
// 
// This file is part of Readup.
// 
// Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
// 
// Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
// 
// You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

import UIKit
import WebKit
import SafariServices
import os.log
import AuthenticationServices

private struct ReaderScriptInitData : Encodable {
    let appPlatform: AppPlatform
    let appVersion: String
    let displayPreference: DisplayPreference?
}

class ArticleViewController:
    UIViewController,
    MessageWebViewDelegate,
    ASWebAuthenticationPresentationContextProviding
{
    private let apiServer = APIServerURLSession()
    private var commitErrorCount = 0
    private var displayTheme: DisplayTheme!
    private var hasParsedPage = false
    private var isStatusBarVisible = true
    override var prefersStatusBarHidden: Bool {
        return !isStatusBarVisible
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if displayTheme == .dark {
            return .lightContent
        }
        if #available(iOS 13.0, *) {
            return .darkContent
        }
        return .default
    }
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    private let params: ArticleViewControllerParams
    private var readOptions: ArticleReadOptions?
    private let errorMessage = UILabel()
    private var webView: MessageWebView!
    private var webViewContainer: WebViewContainer!
    private var webAuthSession: NSObject?
    init(params: ArticleViewControllerParams) {
        self.params = params
        self.readOptions = params.articleReadOptions
        super.init(nibName: nil, bundle: nil)
        // set theme
        let displayPreference = LocalStorage.getDisplayPreference()
        displayTheme = DisplayPreferenceService.resolveDisplayTheme(
            traits: traitCollection,
            preference: displayPreference
        )
        // init webview
        let config = WKWebViewConfiguration()
        let initData = ReaderScriptInitData(
            appPlatform: getAppPlatform(),
            appVersion: SharedBundleInfo.version.description,
            displayPreference: displayPreference
        )
        let encoder = JSONEncoder.init()
        let initJson = String(
            data: try! encoder.encode([
                "nativeClient" : [
                    "reader": [
                        "initData": initData
                    ]
                ]
            ]),
            encoding: .utf8
        )!
        config.userContentController.addUserScript(
            WKUserScript(
                source: "window.reallyreadit = \(initJson);",
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            )
        )
        webView = MessageWebView(
            webViewConfig: config,
            javascriptListenerObject: "window.reallyreadit.nativeClient.reader",
            injectedScript: AppBundleInfo.readerScript
        )
        webView.delegate = self
        webView.view.customUserAgent = "'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.77 Safari/537.36'"
        webView.view.scrollView.bouncesZoom = false
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
            "The article failed to load.",
            "Please check your internet connection and try again.",
            "Drop us a line in our Discord if this problem persists."
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
        let backButton = UIButton(type: .system)
        backButton.setTitle("Go Back", for: .normal)
        backButton.setTitleColor(.systemBlue, for: .normal)
        backButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        backButton.translatesAutoresizingMaskIntoConstraints = false
        errorContent.addSubview(backButton)
        NSLayoutConstraint.activate([
            errorContent.centerYAnchor.constraint(equalTo: webViewContainer.errorView.centerYAnchor),
            errorContent.topAnchor.constraint(equalTo: errorContent.subviews[0].topAnchor),
            errorContent.bottomAnchor.constraint(equalTo: errorContent.subviews.last!.bottomAnchor),
            errorContent.leadingAnchor.constraint(equalTo: webViewContainer.errorView.leadingAnchor),
            errorContent.trailingAnchor.constraint(equalTo: webViewContainer.errorView.trailingAnchor),
            errorMessage.centerXAnchor.constraint(equalTo: errorContent.centerXAnchor),
            errorMessage.leadingAnchor.constraint(greaterThanOrEqualTo: errorContent.leadingAnchor, constant: 8),
            errorMessage.trailingAnchor.constraint(lessThanOrEqualTo: errorContent.trailingAnchor, constant: 8),
            backButton.centerXAnchor.constraint(equalTo: errorContent.centerXAnchor),
            backButton.topAnchor.constraint(
                equalTo: errorContent.subviews[errorContent.subviews.count - 2].bottomAnchor,
                constant: 8
            )
        ])
        // theme webview
        webViewContainer.setDisplayTheme(theme: displayTheme)
    }
    required init?(coder: NSCoder) {
        return nil
    }
    @objc private func close() {
        params.onClose()
    }
    private func loadArticle(reference: ArticleReference) {
        switch reference {
        case .slug(let slug):
            loadArticle(slug: slug)
        case .url(let url):
            loadArticle(url: url)
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
                                URL(
                                    string: url.absoluteString.replacingOccurrences(
                                        of: "^http:",
                                        with: "https:",
                                        options: [.regularExpression, .caseInsensitive]
                                    )
                                )!
                            )
                        )
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
    private func setStatusBarVisibility(isVisible: Bool) {
        if isStatusBarVisible == isVisible {
            return
        }
        isStatusBarVisible = isVisible
        UIView.animate(withDuration: 0.25) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    private func updateDisplayPreference(preference: DisplayPreference) {
        displayTheme = DisplayPreferenceService.resolveDisplayTheme(traits: traitCollection, preference: preference)
        setNeedsStatusBarAppearanceUpdate()
        webViewContainer.setDisplayTheme(theme: displayTheme)
    }
    override func loadView() {
        view = webViewContainer.view
    }
    func onMessage(message: (type: String, data: Any?), callbackId: Int?) {
        switch message.type {
        case "changeDisplayPreference":
            let preference = DisplayPreference(serializedPreference: message.data as! [String: Any])!
            LocalStorage.setDisplayPreference(preference: preference)
            updateDisplayPreference(preference: preference)
            params.onDisplayPreferenceChanged(preference)
            apiServer.postJson(
                path: "/UserAccounts/DisplayPreference",
                data: preference,
                onSuccess: {
                    [weak self] (preference: DisplayPreference) in
                    if let self = self {
                        DispatchQueue.main.async {
                            self.webView.sendResponse(data: preference, callbackId: callbackId!)
                        }
                    }
                },
                onError: {
                    [weak self] _ in
                    if let self = self {
                        DispatchQueue.main.async {
                            self.setErrorState(withMessage: "Error saving display preference.")
                        }
                    }
                }
            )
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
                            self.params.onArticleUpdated(
                                ArticleUpdatedEvent(
                                    article: article,
                                    isCompletionCommit: event.isCompletionCommit
                                )
                            )
                            self.webView.sendResponse(
                                data: WebViewResult<Article, ProblemDetails>(article),
                                callbackId: callbackId!
                            )
                        }
                    }
                },
                onError: {
                    [weak self] error in
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
                            self.setErrorState(withMessage: "Error deleting comment.")
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
        case "getDisplayPreference":
            webView.sendResponse(
                data: LocalStorage.getDisplayPreference(),
                callbackId: callbackId!
            )
            apiServer.getJson(
                path: "/UserAccounts/DisplayPreference",
                onSuccess: {
                    [weak self] (preference: DisplayPreference?) in
                    if let self = self {
                        DispatchQueue.main.async {
                            guard let preference = preference else {
                                return
                            }
                            if
                                let storedPreference = LocalStorage.getDisplayPreference(),
                                storedPreference == preference
                            {
                                return
                            }
                            LocalStorage.setDisplayPreference(preference: preference)
                            self.updateDisplayPreference(preference: preference)
                            self.webView.sendMessage(
                                message: Message(
                                    type: "displayPreferenceChanged",
                                    data: preference
                                )
                            )
                            self.params.onDisplayPreferenceChanged(preference)
                        }
                    }
                },
                onError: {
                    _ in os_log("error fetching display preference")
                }
            )
        case "navBack":
            close()
        case "navTo":
            if let url = URL(string: message.data as! String) {
                params.onNavTo(url)
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
                presentSafariViewController(
                    url: url,
                    theme: displayTheme,
                    completionHandler: nil
                )
            }
        case "openExternalUrlUsingSystem":
            if let url = URL(string: message.data as! String) {
                UIApplication.shared.open(url)
            }
        case "openExternalUrlWithCompletionHandler":
            if let url = URL(string: message.data as! String) {
                presentSafariViewController(
                    url: url,
                    theme: displayTheme,
                    completionHandler: {
                        [weak self] in
                        guard let self = self else {
                            return
                        }
                        self.webView.sendResponse(data: ExternalURLCompletionEvent(), callbackId: callbackId!)
                    }
                )
            }
        case "parseResult":
            hasParsedPage = true
            let starArticle = readOptions?.star ?? false
            apiServer.postJson(
                path: "/Extension/GetUserArticle",
                data: PageParseResult(
                    contentScriptData: message.data as! [String: Any],
                    star: starArticle
                ),
                onSuccess: {
                    [weak self] (result: ArticleLookupResult) in
                    if let self = self {
                        DispatchQueue.main.async {
                            if (starArticle) {
                                self.params.onArticleStarred(
                                    ArticleStarredEvent(article: result.userArticle)
                                )
                            }
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
                                        isAuthor: false,
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
                            self.setErrorState(withMessage: "Error posting article.")
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
                            self.setErrorState(withMessage: "Error posting comment revision.")
                        }
                    }
                }
            )
        case "readArticle":
            replaceArticle(reference: .slug(message.data as! String))
        case "reportArticleIssue":
            apiServer.postJson(
                path: "/Analytics/ArticleIssueReport",
                data: ArticleIssueReportRequest(message.data as! [String: Any]),
                onSuccess: { },
                onError: { _ in }
            )
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
        case "setStatusBarVisibility":
            if let isVisible = message.data as? Bool {
                setStatusBarVisibility(isVisible: isVisible)
            }
        case "share":
            presentActivityViewController(
                data: ShareData(message.data as! [String: Any]),
                theme: displayTheme,
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
        case "starArticle":
            apiServer.postJson(
                path: "/Articles/Star",
                data: StarArticleRequest(message.data as! [String: Any]),
                onSuccess: {
                    [weak self] (result: Article) in
                    if let self = self {
                        DispatchQueue.main.async {
                            self.params.onArticleUpdated(
                                ArticleUpdatedEvent(
                                    article: result,
                                    isCompletionCommit: false
                                )
                            )
                            self.params.onArticleStarred(
                                ArticleStarredEvent(article: result)
                            )
                            self.webView.sendResponse(data: result, callbackId: callbackId!)
                        }
                    }
                },
                onError: {
                    [weak self] _ in
                    if let self = self {
                        DispatchQueue.main.async {
                            self.setErrorState(withMessage: "Error starring article.")
                        }
                    }
                }
            )
        case "unstarArticle":
            apiServer.postJson(
                path: "/Articles/Unstar",
                data: StarArticleRequest(message.data as! [String: Any]),
                onSuccess: {
                    [weak self] (result: Article) in
                    if let self = self {
                        DispatchQueue.main.async {
                            self.params.onArticleUpdated(
                                ArticleUpdatedEvent(
                                    article: result,
                                    isCompletionCommit: false
                                )
                            )
                            self.webView.sendResponse(data: result, callbackId: callbackId!)
                        }
                    }
                },
                onError: {
                    [weak self] _ in
                    if let self = self {
                        DispatchQueue.main.async {
                            self.setErrorState(withMessage: "Error unstarring article.")
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
    func replaceArticle(reference: ArticleReference, options: ArticleReadOptions? = nil) {
        commitErrorCount = 0
        hasParsedPage = false
        readOptions = options
        webViewContainer.setState(.loading)
        loadArticle(reference: reference)
    }
    func setErrorState(withMessage message: String) {
        errorMessage.text = message
        webViewContainer.setState(.error)
        setStatusBarVisibility(isVisible: true)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // fetch and preprocess the article
        loadArticle(reference: params.articleReference)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if self.isBeingDismissed || self.isMovingFromParent {
            // clean up webview
            webView.dispose()
            // show status bar with animation
            setStatusBarVisibility(isVisible: true)
        }
    }
}
