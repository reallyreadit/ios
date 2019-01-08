import UIKit
import WebKit
import os.log

class WebAppViewController: WebViewViewController {
    private let ghostWhite = UIColor(red: 248 / 255, green: 248 / 255, blue: 255 / 255, alpha: 1)
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
        // init super to create webview
        super.init(coder: coder)
        // configure webview
        webView.customUserAgent = "reallyread.it iOS App WebView"
        webView.scrollView.bounces = false
        // configre the loading view
        loadingView.backgroundColor = ghostWhite
        // configure the error view
        errorView.backgroundColor = ghostWhite
        let errorContent = UIView()
        errorContent.translatesAutoresizingMaskIntoConstraints = false
        errorView.addSubview(errorContent)
        [
            "An error occured while loading the app.",
            "You must be online to use reallyread.it.",
            "Offline support coming soon!"
        ]
        .forEach({
            line in
            let label = UILabel(frame: .zero)
            label.text = line
            label.translatesAutoresizingMaskIntoConstraints = false
            errorContent.addSubview(label)
            label.centerXAnchor.constraint(equalTo: errorContent.centerXAnchor).isActive = true
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
            errorContent.centerYAnchor.constraint(equalTo: errorView.centerYAnchor),
            errorContent.topAnchor.constraint(equalTo: errorContent.subviews[0].topAnchor),
            errorContent.bottomAnchor.constraint(equalTo: errorContent.subviews.last!.bottomAnchor),
            errorContent.leadingAnchor.constraint(equalTo: errorView.leadingAnchor),
            errorContent.trailingAnchor.constraint(equalTo: errorView.trailingAnchor),
            reloadButton.centerXAnchor.constraint(equalTo: errorContent.centerXAnchor),
            reloadButton.topAnchor.constraint(
                equalTo: errorContent.subviews[errorContent.subviews.count - 2].bottomAnchor,
                constant: 8
            )
        ])
        // set session key
        setSessionKeyFromWebview()
    }
    @objc private func loadWebApp() {
        loadURL(URL(string: "http://dev.reallyread.it")!)
    }
    private func setBackgroundColor() {
        if state == .loaded, sessionKey != nil {
            view.backgroundColor = UIColor(red: 234 / 255, green: 234 / 255, blue: 234 / 255, alpha: 1)
        } else {
            view.backgroundColor = ghostWhite
        }
    }
    private func setSessionKeyFromWebview() {
        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies({
            cookies in
            // set the session key
            if
                let sessionCookie = cookies.first(where: {
                    cookie in
                    cookie.domain == ".dev.reallyread.it" && cookie.name == "devSessionKey"
                })
            {
                os_log(.debug, "setSessionKeyFromWebview(): authenticated")
                self.sessionKey = sessionCookie.value
            } else {
                os_log(.debug, "setSessionKeyFromWebview(): unauthenticated")
                self.sessionKey = nil
            }
            // set the background color
            self.setBackgroundColor()
        })
    }
    override func cookiesDidChange(in cookieStore: WKHTTPCookieStore) {
        setSessionKeyFromWebview()
    }
    func loadURL(_ url: URL) {
        os_log(.debug, "loadURL(_:): loading: %s", url.absoluteString)
        webView.load(
            URLRequest(
                url: url
            )
        )
    }
    override func loadView() {
        view = UIView()
        view.backgroundColor = ghostWhite
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
    override func setState(_ state: WebViewState) {
        super.setState(state)
        setBackgroundColor()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // hide the navigation bar
        navigationController!.setNavigationBarHidden(true, animated: false)
        // add the webview container as a subview
        view.addSubview(webViewContainer)
        webViewContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webViewContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webViewContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webViewContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webViewContainer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        // load the webview
        loadWebApp()
    }
}
