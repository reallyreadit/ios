import UIKit
import WebKit
import os.log

class WebAppViewController: WebViewViewController {
    // status bar config
    private var hideStatusBar = false
    override var prefersStatusBarHidden: Bool {
        return hideStatusBar
    }
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    // webview authentication
    var sessionKey: String?
    required init?(coder: NSCoder) {
        // configure webview
        super.init(coder: coder)
        webView.customUserAgent = "reallyread.it iOS App WebView"
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.scrollView.bounces = false
        // update auth state
        updateAuthStateFromWebview()
    }
    private func updateAuthStateFromWebview() {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies({
            cookies in
            if
                let sessionCookie = cookies.first(where: {
                    cookie in
                    cookie.domain == ".dev.reallyread.it" && cookie.name == "devSessionKey"
                })
            {
                os_log(.debug, "updateAuthStateFromWebview(): authenticated")
                self.sessionKey = sessionCookie.value
                self.view.backgroundColor = UIColor(red: 234 / 255, green: 234 / 255, blue: 234 / 255, alpha: 1)
            } else {
                os_log(.debug, "updateAuthStateFromWebview(): unauthenticated")
                self.sessionKey = nil
                self.view.backgroundColor = UIColor(red: 248 / 255, green: 248 / 255, blue: 255 / 255, alpha: 1)
            }
        })
    }
    override func cookiesDidChange(in cookieStore: WKHTTPCookieStore) {
        updateAuthStateFromWebview()
    }
    func loadURL(_ url: URL) {
        webView.load(
            URLRequest(
                url: url
            )
        )
    }
    override func loadView() {
        view = UIView()
    }
    override func onMessage(message: (type: String, data: Any?), callbackId: Int?) {
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
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if
            let destination = segue.destination as? ArticleViewController,
            let data = sender as? [String: Any]
        {
            // hide status bar with animation
            hideStatusBar = true
            UIView.animate(withDuration: 0.25) {
                self.setNeedsStatusBarAppearanceUpdate()
            }
            // show navigation bar
            navigationController!.setNavigationBarHidden(false, animated: true)
            navigationController!.hidesBarsOnSwipe = true
            // set view controller params
            destination.params = ArticleViewControllerParams(
                article: ArticleViewControllerArticleParam(
                    title: data["title"] as! String,
                    url: URL(string: data["url"] as! String)!
                ),
                onClose: {
                    // set status bar to hidden
                    self.hideStatusBar = false
                    // hide navigation bar
                    self.navigationController!.setNavigationBarHidden(true, animated: true)
                    self.navigationController!.hidesBarsOnSwipe = false
                },
                onReadStateCommitted: {
                    event in
                    self.sendMessage(
                        message: Message(
                            type: "articleUpdated",
                            data: event
                        )
                    )
                },
                sessionKey: sessionKey!
            )
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // hide the navigation bar
        navigationController!.setNavigationBarHidden(true, animated: false)
        // add the webview as a subview
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            ])
        // load the webview
        webView.load(
            URLRequest(
                url: URL(string: "http://dev.reallyread.it")!
            )
        )
    }
}
