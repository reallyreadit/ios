import UIKit
import Social
import WebKit

class ShareViewController: SLComposeServiceViewController, MessageWebViewDelegate {
    private var url: URL?
    private var webView: MessageWebView!
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        let config = WKWebViewConfiguration()
        ArticleReading.addContentScript(forConfiguration: config)
        webView = MessageWebView(webViewConfig: config)
        webView.delegate = self
    }
    func onMessage(message: (type: String, data: Any?), callbackId: Int?) {
        switch message.type {
        case "registerContentScript":
            print("registerContentScript")
            webView.sendResponse(
                data: ContentScriptInitData(
                    config: ContentScriptConfig(
                        idleReadRate: 500,
                        pageOffsetUpdateRate: 3000,
                        readStateCommitRate: 3000,
                        readWordRate: 100
                    ),
                    loadPage: true,
                    parseMetadata: true,
                    parseMode: "analyze",
                    showOverlay: false,
                    sourceRules: []
                ),
                callbackId: callbackId!
            )
        case "registerPage":
            print("registerPage")
            APIServer.postJson(
                path: "/Extension/GetUserArticle",
                data: PageParseResult(message.data as! [String: Any]),
                onSuccess: {
                    (result: ArticleLookupResult) in
                    print("starred: " + result.userArticle.title)
                },
                onError: {
                    _ in
                    print("error starring article")
                }
            )
        default:
            return
        }
    }
    
    override func isContentValid() -> Bool {
        // Do validation of contentText and/or NSExtensionContext attachments here
        return true
    }

    override func didSelectPost() {
        // This is called after the user selects Post. Do the upload of contentText and/or NSExtensionContext attachments.
    
        // Inform the host that we're done, so it un-blocks its UI. Note: Alternatively you could call super's -didSelectPost, which will similarly complete the extension context.
        print("didSelectPost()")
        self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
        
        /*let config = URLSessionConfiguration.default
        config.httpCookieStorage = HTTPCookieStorage.sharedCookieStorage(
            forGroupContainerIdentifier: "group.it.reallyread"
        )
        URLSession(configuration: config)
            .dataTask(
                with: URLRequest(
                    url: URL(string: "http://api.dev.reallyread.it/HealthCheck/Check")!
                ),
                completionHandler: {
                    data, response, error in
                    if
                        error == nil,
                        let httpResponse = response as? HTTPURLResponse,
                        (200...299).contains(httpResponse.statusCode)
                    {
                        print("OK")
                    } else {
                        print("Bad request")
                    }
                    self.extensionContext!.completeRequest(returningItems: [], completionHandler: nil)
                }
            )
            .resume()*/
    }
    
    override func viewDidLoad() {
        if
            let item = extensionContext?.inputItems.first as? NSExtensionItem,
            let urlAttachment = item.attachments?.first(where: {
                attachment in attachment.hasItemConformingToTypeIdentifier("public.url")
            })
        {
            urlAttachment.loadItem(
                forTypeIdentifier: "public.url",
                options: nil,
                completionHandler: {
                    [weak self] value, error in
                    if
                        let self = self,
                        let url = value as? URL
                    {
                        self.url = url
                        ArticleReading.fetchArticle(
                            url: url,
                            onSuccess: {
                                [weak self] content in
                                if let self = self {
                                    DispatchQueue.main.async {
                                        self.webView.view.loadHTMLString(
                                            content as String,
                                            baseURL: url
                                        )
                                    }
                                }
                            },
                            onError: {
                                print("Error loading article.")
                            }
                        )
                    }
                }
            )
        }
    }

    override func configurationItems() -> [Any]! {
        // To add configuration options via table cells at the bottom of the sheet, return an array of SLComposeSheetConfigurationItem here.
        return []
    }

}
