import UIKit
import WebKit
import os.log

class WebAppViewController:
    UIViewController,
    MessageWebViewDelegate,
    WebViewContainerDelegate,
    WKHTTPCookieStoreObserver
{
    private var hasCalledWebViewLoad = false
    private let newsprint = UIColor(red: 247 / 255, green: 246 / 255, blue: 245 / 255, alpha: 1)
    private var isAuthenticated = false
    private var webView: MessageWebView!
    private var webViewContainer: WebViewContainer!
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        let config = WKWebViewConfiguration()
        config.websiteDataStore.httpCookieStore.add(self)
        webView = MessageWebView(
            webViewConfig: config,
            javascriptListenerObject: "window.reallyreadit.app"
        )
        webView.delegate = self
        webViewContainer = WebViewContainer(webView: webView.view)
        webViewContainer.delegate = self
        // configure webview
        webView.view.scrollView.bounces = false
        // configre the loading view
        webViewContainer.loadingView.backgroundColor = newsprint
        // configure the error view
        webViewContainer.errorView.backgroundColor = newsprint
        let errorContent = UIView()
        errorContent.translatesAutoresizingMaskIntoConstraints = false
        webViewContainer.errorView.addSubview(errorContent)
        [
            "An error occured while loading the app.",
            "You must be online to use Readup.",
            "Offline support coming soon!"
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
                label.leadingAnchor.constraint(greaterThanOrEqualTo: errorContent.leadingAnchor, constant: 8),
                label.trailingAnchor.constraint(lessThanOrEqualTo: errorContent.trailingAnchor, constant: 8)
            ])
            if errorContent.subviews.count > 1 {
                label.topAnchor
                    .constraint(
                        equalTo: errorContent.subviews[errorContent.subviews.count - 2].bottomAnchor,
                        constant: 8
                    )
                    .isActive = true
            }
        })
        let reloadButton = UIButton(type: .system)
        reloadButton.setTitle("Try Again", for: .normal)
        reloadButton.addTarget(self, action: #selector(loadWebApp), for: .touchUpInside)
        reloadButton.translatesAutoresizingMaskIntoConstraints = false
        errorContent.addSubview(reloadButton)
        NSLayoutConstraint.activate([
            errorContent.centerYAnchor.constraint(equalTo: webViewContainer.errorView.centerYAnchor),
            errorContent.topAnchor.constraint(equalTo: errorContent.subviews[0].topAnchor),
            errorContent.bottomAnchor.constraint(equalTo: errorContent.subviews.last!.bottomAnchor),
            errorContent.leadingAnchor.constraint(equalTo: webViewContainer.errorView.leadingAnchor),
            errorContent.trailingAnchor.constraint(equalTo: webViewContainer.errorView.trailingAnchor),
            reloadButton.centerXAnchor.constraint(equalTo: errorContent.centerXAnchor),
            reloadButton.topAnchor.constraint(
                equalTo: errorContent.subviews[errorContent.subviews.count - 2].bottomAnchor,
                constant: 8
            )
        ])
    }
    @objc private func loadWebApp() {
        loadURL(AppBundleInfo.webServerURL)
    }
    private func migrateLegacyAuthCookie(
        _ webAppURL: URL
    ) -> Bool {
        let domainMigrationHasCompletedKey = "domainMigrationHasCompleted";
        let userDefaults = UserDefaults.init(suiteName: "group.it.reallyread")!
        if (!userDefaults.bool(forKey: domainMigrationHasCompletedKey)) {
            userDefaults.set(true, forKey: domainMigrationHasCompletedKey)
            if
                let legacyAuthCookie =  SharedCookieStore.store
                    .cookies(for: URL(string: "https://reallyread.it/")!)?
                    .first(where: { cookie in cookie.name == SharedBundleInfo.authCookieName }),
                var cookieProperties = legacyAuthCookie.properties
            {
                os_log("migrateLegacyAuthCookie: found legacy auth cookie")
                cookieProperties[HTTPCookiePropertyKey.domain] = SharedBundleInfo.authCookieDomain
                if let newCookie = HTTPCookie(properties: cookieProperties) {
                    os_log("migrateLegacyAuthCookie: setting new auth cookie")
                    webView.view.configuration.websiteDataStore.httpCookieStore.setCookie(
                        newCookie,
                        completionHandler: {
                            [weak self, webAppURL] in
                            if let self = self {
                                os_log("loadURL(_:): loading: %s", webAppURL.absoluteString)
                                self.webView.view.load(
                                    URLRequest(
                                        url: webAppURL
                                    )
                                )
                                self.hasCalledWebViewLoad = true
                            }
                        }
                    )
                    return true
                }
            }
        }
        return false
    }
    private func prepareURL(_ url: URL) -> URL? {
        if var components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            // force https unless we're in debug mode
            if !SharedBundleInfo.debugReader {
                components.scheme = "https"
            }
            // convert reallyread.it urls to readup.com
            components.host = components.host?.replacingOccurrences(
                of: "reallyread.it",
                with: "readup.com",
                options: [.caseInsensitive]
            )
            // set the client type in the query string
            let clientTypeQueryItem = URLQueryItem(name: "clientType", value: "App")
            if (components.queryItems == nil) {
                components.queryItems = [clientTypeQueryItem]
            } else {
                components.queryItems!.removeAll(where: { item in item.name == "clientType" })
                components.queryItems!.append(clientTypeQueryItem)
            }
            // return the url
            return components.url
        }
        return nil
    }
    private func setBackgroundColor() {
        if webViewContainer.state == .loaded, isAuthenticated {
            view.backgroundColor = UIColor(red: 234 / 255, green: 234 / 255, blue: 234 / 255, alpha: 1)
        } else {
            view.backgroundColor = newsprint
        }
    }
    func cookiesDidChange(in cookieStore: WKHTTPCookieStore) {
        cookieStore.getAllCookies({
            cookies in
            // check for webview cookie
            if let authCookie = cookies.first(where: SharedCookieStore.authCookieMatchPredicate) {
                os_log("cookiesDidChange(in:): authenticated")
                self.isAuthenticated = true
                SharedCookieStore.setCookie(authCookie)
            } else {
                os_log("cookiesDidChange(in:): unauthenticated")
                self.isAuthenticated = false
                SharedCookieStore.clearAuthCookies()
            }
            // set the background color
            self.setBackgroundColor()
        })
    }
    func loadURL(_ url: URL) {
        // prepare the url
        let preparedURL = prepareURL(url) ?? AppBundleInfo.webServerURL
        // domain migration
        if (!migrateLegacyAuthCookie(preparedURL)) {
            os_log("loadURL(_:): loading: %s", preparedURL.absoluteString)
            webView.view.load(
                URLRequest(
                    url: preparedURL
                )
            )
            self.hasCalledWebViewLoad = true
        }
    }
    override func loadView() {
        view = UIView()
        view.backgroundColor = newsprint
    }
    func onMessage(message: (type: String, data: Any?), callbackId: Int?) {
        switch message.type {
        case "getVersion":
            self.webView.sendResponse(
                data: SharedBundleInfo.version.description,
                callbackId: callbackId!
            )
        case "readArticle":
            let data = message.data as! [String: Any]
            performSegue(
                withIdentifier: "readArticle",
                sender: data.keys.contains("url") ?
                    ArticleReference.url(URL(string: data["url"] as! String)!) :
                    ArticleReference.slug(data["slug"] as! String)
            )
        case "share":
            presentActivityViewController(data: ShareData(message.data as! [String: Any]))
        default:
            return
        }
    }
    func onStateChange(state: WebViewContainerState) {
        setBackgroundColor()
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if
            let destination = segue.destination as? ArticleViewController,
            let articleReference = sender as? ArticleReference
        {
            // show navigation bar
            navigationController!.setNavigationBarHidden(false, animated: true)
            // set view controller params
            destination.params = ArticleViewControllerParams(
                articleReference: articleReference,
                onArticleUpdated: {
                    event in
                    self.webView.sendMessage(
                        message: Message(
                            type: "articleUpdated",
                            data: event
                        )
                    )
                },
                onClose: {
                    // hide navigation bar
                    self.navigationController!.setNavigationBarHidden(true, animated: true)
                },
                onCommentPosted: {
                    comment in
                    self.webView.sendMessage(
                        message: Message(
                            type: "commentPosted",
                            data: comment
                        )
                    )
                }
            )
        }
    }
    func readArticle(slug: String) {
        performSegue(
            withIdentifier: "readArticle",
            sender: ArticleReference.slug(slug)
        )
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // hide the navigation bar
        navigationController!.setNavigationBarHidden(true, animated: false)
        // add the webview container as a subview
        view.addSubview(webViewContainer.view)
        webViewContainer.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webViewContainer.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webViewContainer.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webViewContainer.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webViewContainer.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        // trigger cookie change to set auth state
        cookiesDidChange(in: webView.view.configuration.websiteDataStore.httpCookieStore)
        // check loading state
        if (!hasCalledWebViewLoad) {
            loadWebApp()
        }
    }
}
