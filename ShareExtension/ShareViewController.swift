import UIKit
import Social
import WebKit

private let redirectSites = [
    "news.google.com": try! NSRegularExpression(
        pattern: "<noscript>.*<a\\b[^>]*href=(['\"])(?<url>(?:(?!\\1).)*)\\1[^>]*>.*</noscript>",
        options: .caseInsensitive
    ),
    "apple.news": try! NSRegularExpression(
        pattern: "<a\\b[^>]*href=(['\"])(?<url>(?:(?!\\1).)*)\\1[^>]*>\\s*click\\s+here\\s*</a>",
        options: .caseInsensitive
    )
]
private func findFirstItemProvider(
    in context: NSExtensionContext?,
    for identifier: String
) -> NSItemProvider? {
    return context?
        .inputItems
        .reduce([NSItemProvider](), {
            urlAttachments, item in
            if
                let item = item as? NSExtensionItem,
                let attachments = item.attachments
            {
                return urlAttachments + attachments.filter({
                    attachment in attachment.hasItemConformingToTypeIdentifier(identifier)
                })
            }
            return urlAttachments
        })
        .first
}
class ShareViewController: UIViewController, MessageWebViewDelegate {
    private var alert: AlertViewController!
    private let apiServer = APIServerURLSession()
    private var hasParsedPage = false
    private var isCancelled = false
    private var url: URL?
    private var webView: MessageWebView!
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nil, bundle: nil)
        // configure webview
        let config = WKWebViewConfiguration()
        webView = MessageWebView(
            webViewConfig: config,
            javascriptListenerObject: "window.reallyreadit.nativeClient.shareExtension",
            injectedScript: SharedBundleInfo.shareExtensionScript
        )
        webView.delegate = self
        // configure alert
        alert = AlertViewController(
            onClose: {
                [weak self] in
                self?.close()
            }
        )
    }
    required init?(coder aDecoder: NSCoder) {
        return nil
    }
    private func close() {
        isCancelled = true
        dismiss(
            animated: true,
            completion: {
                [weak self] in
                self?.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
            }
        )
    }
    private func loadArticle(url: URL) {
        self.url = url
        ArticleProcessing.fetchArticle(
            url: url,
            mode: .shareExtension,
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
                        deadline: .now() + .seconds(30),
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
    private func processUrl(_ url: URL) {
        if url.host == SharedBundleInfo.webServerURL.host {
            self.alert.showError(withText: "Use this button to import articles from other apps to Readup.")
            return
        }
        self.alert.showLoadingMessage(withText: "Loading article")
        if let redirectRegex = redirectSites[url.host!] {
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
                            let match = redirectRegex.firstMatch(
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
    override func loadView() {
        view = UIView()
    }
    func onMessage(message: (type: String, data: Any?), callbackId: Int?) {
        if isCancelled {
            return
        }
        switch message.type {
        case "parseResult":
            hasParsedPage = true
            alert.showLoadingMessage(withText: "Saving article")
            apiServer.postJson(
                path: "/Extension/GetUserArticle",
                data: PageParseResult(
                    contentScriptData: message.data as! [String: Any],
                    star: true
                ),
                onSuccess: {
                    [weak self] (result: ArticleLookupResult) in
                    if
                        let self = self,
                        !self.isCancelled
                    {
                        UNUserNotificationCenter
                            .current()
                            .getNotificationSettings {
                                settings in
                                if settings.authorizationStatus == .authorized {
                                    let slugParts = result.userArticle.slug.split(separator: "_")
                                    
                                    let content = UNMutableNotificationContent()
                                    content.title = result.userArticle.title
                                    content.subtitle = "⭐️ Starred in My Reads"
                                    content.userInfo["url"] = SharedBundleInfo.webServerURL
                                        .appendingPathComponent("/read/\(slugParts[0])/\(slugParts[1])")
                                        .absoluteString
                                    
                                    let request = UNNotificationRequest(
                                        identifier: UUID().uuidString,
                                        content: content,
                                        trigger: nil
                                    )

                                    UNUserNotificationCenter
                                        .current()
                                        .add(request) {
                                            error in
                                            if error == nil {
                                                self.close()
                                            } else {
                                                DispatchQueue.main.async {
                                                    self.alert.showSuccess(withText: "Article saved")
                                                }
                                            }
                                        }
                                } else {
                                    DispatchQueue.main.async {
                                        self.alert.showSuccess(withText: "Article saved")
                                    }
                                }
                            }
                    }
                    LocalStorage.setExtensionNewStarCount(
                        count: LocalStorage.getExtensionNewStarCount() + 1
                    )
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
        // check for auth cookie
        if SharedCookieStore.isAuthenticated() {
            // check urls first and fall back to text
            // it seems like iOS 13+ might automatically parse text to URLs
            // but earlier versions definitely do not and must be parsed manually
            if let urlAttachment = findFirstItemProvider(in: extensionContext, for: "public.url") {
                urlAttachment.loadItem(
                    forTypeIdentifier: "public.url",
                    options: nil,
                    completionHandler: {
                        [weak self] value, error in
                        if
                            let self = self,
                            !self.isCancelled
                        {
                            if let url = value as? URL {
                                self.processUrl(url)
                            } else {
                                self.alert.showError(withText: "Error accessing article URL")
                            }
                        }
                    }
                )
            } else if let textAttachment = findFirstItemProvider(in: extensionContext, for: "public.text") {
                textAttachment.loadItem(
                    forTypeIdentifier: "public.text",
                    options: nil,
                    completionHandler: {
                        [weak self] value, error in
                        if
                            let self = self,
                            !self.isCancelled
                        {
                            if
                                let text = value as? String,
                                let url = URL(string: text)
                            {
                                self.processUrl(url)
                            } else {
                                self.alert.showError(withText: "Error accessing article URL")
                            }
                        }
                    }
                )
            } else {
                alert.showError(withText: "Error accessing article URL")
            }
        } else {
            alert.showError(withText: "Please sign in using the Readup app")
        }
    }
}
