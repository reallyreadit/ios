import UIKit
import Social
import WebKit

private let appleNewsURLRegex = try! NSRegularExpression(
    pattern: "<a\\b[^>]*href=(['\"])(?<url>(?:(?!\\1).)*)\\1[^>]*>\\s*click\\s+here\\s*</a>",
    options: .caseInsensitive
)
class ShareViewController: UIViewController, MessageWebViewDelegate {
    private var alert: AlertViewController!
    private var hasParsedPage = false
    private var isCancelled = false
    private var url: URL?
    private var webView: MessageWebView!
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        // configure webview
        let config = WKWebViewConfiguration()
        ArticleProcessing.addContentScript(forConfiguration: config)
        webView = MessageWebView(webViewConfig: config)
        webView.delegate = self
        // configure alert
        alert = AlertViewController(
            onClose: {
                [weak self] in
                self?.isCancelled = true
                self?.dismiss(
                    animated: true,
                    completion: {
                        [weak self] in
                        self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
                    }
                )
            }
        )
    }
    private func loadArticle(url: URL) {
        self.url = url
        ArticleProcessing.fetchArticle(
            url: url,
            onSuccess: {
                [weak self] content in
                if
                    let self = self,
                    !self.isCancelled
                {
                    DispatchQueue.main.async {
                        self.alert.showLoadingMessage(withText: "Parsing article")
                        self.webView.view.loadHTMLString(
                            content as String,
                            baseURL: url
                        )
                    }
                    DispatchQueue.main.asyncAfter(
                        deadline: .now() + .seconds(3),
                        execute: {
                            [weak self] in
                            if
                                let self = self,
                                !self.isCancelled,
                                !self.hasParsedPage
                            {
                                self.isCancelled = true
                                self.alert.showError(withText: "Error parsing article")
                            }
                        }
                    )
                }
            },
            onError: {
                [weak self] in
                if
                    let self = self,
                    !self.isCancelled
                {
                    DispatchQueue.main.async {
                        self.alert.showError(withText: "Error loading article")
                    }
                }
            }
        )
    }
    override func loadView() {
        view = UIView()
    }
    func onMessage(message: (type: String, data: Any?), callbackId: Int?) {
        if isCancelled {
            return
        }
        switch message.type {
        case "registerContentScript":
            webView.sendResponse(
                data: ContentScriptInitData(
                    config: ContentScriptConfig(
                        idleReadRate: 0,
                        pageOffsetUpdateRate: 0,
                        readStateCommitRate: 0,
                        readWordRate: 0
                    ),
                    loadPage: true,
                    parseMetadata: true,
                    parseMode: "analyze",
                    showOverlay: false,
                    sourceRules: [
                        SourceRule(
                            id: 0,
                            hostname: url!.host!,
                            path: "^/",
                            priority: 0,
                            action: .read
                        )
                    ]
                ),
                callbackId: callbackId!
            )
        case "registerPage":
            hasParsedPage = true
            alert.showLoadingMessage(withText: "Saving article")
            APIServer.postJson(
                path: "/Extension/GetUserArticle",
                data: PageParseResult(
                    contentScriptData: message.data as! [String: Any],
                    star: true
                ),
                onSuccess: {
                    [weak self] (_: ArticleLookupResult) in
                    if
                        let self = self,
                        !self.isCancelled
                    {
                        DispatchQueue.main.async {
                            self.alert.showError(withText: "Article saved")
                        }
                    }
                },
                onError: {
                    [weak self] _ in
                    if
                        let self = self,
                        !self.isCancelled
                    {
                        DispatchQueue.main.async {
                            self.alert.showError(withText: "Error saving article")
                        }
                    }
                }
            )
        default:
            return
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        present(alert, animated: true)
    }
    override func viewDidLoad() {
        // get shared cookie container
        let sharedCookieStore = HTTPCookieStorage.sharedCookieStorage(
            forGroupContainerIdentifier: "group.it.reallyread"
        )
        // check for auth cookie
        if
            sharedCookieStore.cookies?.contains(where: {
                cookie in
                (
                    cookie.domain == Bundle.main.infoDictionary!["RRITAuthCookieDomain"] as! String &&
                    cookie.name == Bundle.main.infoDictionary!["RRITAuthCookieName"] as! String
                )
            }) ?? false
        {
            // try to find the url
            if
                let urlAttachment = extensionContext?
                    .inputItems
                    .reduce([NSItemProvider](), {
                        urlAttachments, item in
                        if
                            let item = item as? NSExtensionItem,
                            let attachments = item.attachments
                        {
                            return urlAttachments + attachments.filter({
                                attachment in attachment.hasItemConformingToTypeIdentifier("public.url")
                            })
                        }
                        return urlAttachments
                    })
                    .first
            {
                urlAttachment.loadItem(
                    forTypeIdentifier: "public.url",
                    options: nil,
                    completionHandler: {
                        [weak self] value, error in
                        if
                            let self = self,
                            !self.isCancelled,
                            let url = value as? URL
                        {
                            self.alert.showLoadingMessage(withText: "Loading article")
                            if url.absoluteString.starts(with: "https://apple.news/") {
                                URLSession
                                    .shared
                                    .dataTask(
                                        with: URLRequest(url: url),
                                        completionHandler: {
                                            [weak self] (data, response, error) in
                                            if
                                                let self = self,
                                                !self.isCancelled,
                                                error == nil,
                                                let httpResponse = response as? HTTPURLResponse,
                                                (200...299).contains(httpResponse.statusCode),
                                                let data = data,
                                                let stringData = String(data: data, encoding: .utf8),
                                                let match = appleNewsURLRegex.firstMatch(
                                                    in: stringData,
                                                    options: [],
                                                    range: NSRange(
                                                        stringData.startIndex...,
                                                        in: stringData
                                                    )
                                                ),
                                                let urlMatchRange = Range(
                                                    match.range(withName: "url"),
                                                    in: stringData
                                                ),
                                                let url = URL(string: String(stringData[urlMatchRange]))
                                            {
                                                DispatchQueue.main.async {
                                                    self.loadArticle(url: url)
                                                }
                                            }
                                            else if
                                                let self = self,
                                                !self.isCancelled
                                            {
                                                DispatchQueue.main.async {
                                                    self.alert.showError(withText: "Error locating publisher URL")
                                                }
                                            }
                                        }
                                    )
                                    .resume()
                            } else {
                                self.loadArticle(url: url)
                            }
                        }
                    }
                )
            } else {
                alert.showError(withText: "Error accessing article URL")
            }
        } else {
            alert.showError(withText: "Please sign in using the reallyread.it app")
        }
    }
}
