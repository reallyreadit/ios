import UIKit
import WebKit
import os.log

class WebAppViewController:
    UIViewController,
    MessageWebViewDelegate,
    WebViewContainerDelegate,
    WKHTTPCookieStoreObserver
{
    private let authCookieMatchPredicate: (_: HTTPCookie) -> Bool = {
        cookie in
        return (
            cookie.domain == Bundle.main.infoDictionary!["RRITAuthCookieDomain"] as! String &&
            cookie.name == Bundle.main.infoDictionary!["RRITAuthCookieName"] as! String
        )
    }
    private let ghostWhite = UIColor(red: 248 / 255, green: 248 / 255, blue: 255 / 255, alpha: 1)
    private var isAuthenticated = false
    private var webView: MessageWebView!
    private var webViewContainer: WebViewContainer!
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        let config = WKWebViewConfiguration()
        config.websiteDataStore.httpCookieStore.add(self)
        webView = MessageWebView(webViewConfig: config)
        webView.delegate = self
        webViewContainer = WebViewContainer(webView: webView.view)
        webViewContainer.delegate = self
        // configure webview
        webView.view.scrollView.bounces = false
        // configre the loading view
        webViewContainer.loadingView.backgroundColor = ghostWhite
        // configure the error view
        webViewContainer.errorView.backgroundColor = ghostWhite
        let errorContent = UIView()
        errorContent.translatesAutoresizingMaskIntoConstraints = false
        webViewContainer.errorView.addSubview(errorContent)
        [
            "An error occured while loading the app.",
            "You must be online to use reallyread.it.",
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
        loadURL(URL(string: Bundle.main.infoDictionary!["RRITWebServerURL"] as! String)!)
    }
    private func setBackgroundColor() {
        if webViewContainer.state == .loaded, isAuthenticated {
            view.backgroundColor = UIColor(red: 234 / 255, green: 234 / 255, blue: 234 / 255, alpha: 1)
        } else {
            view.backgroundColor = ghostWhite
        }
    }
    func cookiesDidChange(in cookieStore: WKHTTPCookieStore) {
        cookieStore.getAllCookies({
            cookies in
            // get shared cookie container
            let sharedCookieStore = HTTPCookieStorage.sharedCookieStorage(
                forGroupContainerIdentifier: "group.it.reallyread"
            )
            // check for webview cookie
            if let authCookie = cookies.first(where: self.authCookieMatchPredicate) {
                os_log("cookiesDidChange(in:): authenticated")
                self.isAuthenticated = true
                sharedCookieStore.setCookie(authCookie)
            } else {
                os_log("cookiesDidChange(in:): unauthenticated")
                self.isAuthenticated = false
                sharedCookieStore
                    .cookies?
                    .filter(self.authCookieMatchPredicate)
                    .forEach({
                        cookie in
                        sharedCookieStore.deleteCookie(cookie)
                    })
            }
            // set the background color
            self.setBackgroundColor()
        })
    }
    func loadURL(_ url: URL) {
        if var components = URLComponents(url: url, resolvingAgainstBaseURL: true) {
            let clientTypeQueryItem = URLQueryItem(name: "clientType", value: "App")
            if (components.queryItems == nil) {
                components.queryItems = [clientTypeQueryItem]
            } else {
                components.queryItems!.removeAll(where: { item in item.name == "clientType" })
                components.queryItems!.append(clientTypeQueryItem)
            }
            if let url = components.url {
                os_log("loadURL(_:): loading: %s", url.absoluteString)
                webView.view.load(
                    URLRequest(
                        url: url
                    )
                )
            }
        }
    }
    override func loadView() {
        view = UIView()
        view.backgroundColor = ghostWhite
    }
    func onMessage(message: (type: String, data: Any?), callbackId: Int?) {
        switch message.type {
        case "readArticle":
            performSegue(
                withIdentifier: "readArticle",
                sender: message.data
            )
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
            let data = sender as? [String: Any]
        {
            // show navigation bar
            navigationController!.setNavigationBarHidden(false, animated: true)
            // set view controller params
            destination.params = ArticleViewControllerParams(
                articleURL: URL(string: data["url"] as! String)!,
                onClose: {
                    // hide navigation bar
                    self.navigationController!.setNavigationBarHidden(true, animated: true)
                },
                onReadStateCommitted: {
                    event in
                    self.webView.sendMessage(
                        message: Message(
                            type: "articleUpdated",
                            data: event
                        )
                    )
                }
            )
        }
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
        // load the webview
        loadWebApp()
    }
}
