import UIKit
import WebKit
import SafariServices
import os.log
import AuthenticationServices

private func getDeviceInfo() -> DeviceInfo {
    return DeviceInfo(
        appVersion: SharedBundleInfo.version.description,
        installationId: UIDevice.current.identifierForVendor?.uuidString,
        name: UIDevice.current.name,
        token: LocalStorage.getNotificationToken()
    )
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
        if components.host != SharedBundleInfo.webServerURL.host {
            return nil
        }
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
class WebAppViewController:
    UIViewController,
    MessageWebViewDelegate,
    WebViewContainerDelegate,
    SFSafariViewControllerDelegate,
    ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding,
    ASWebAuthenticationPresentationContextProviding
{
    private var hasCalledWebViewLoad = false
    private var hasEstablishedCommunication = false
    private let newsprint = UIColor(red: 247 / 255, green: 246 / 255, blue: 245 / 255, alpha: 1)
    private var isAuthenticated = false
    private var webAuthSession: NSObject?
    private var webView: MessageWebView!
    private var webViewContainer: WebViewContainer!
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if #available(iOS 13.0, *) {
            return .darkContent
        }
        return .default
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        webView = MessageWebView(
            webViewConfig: WKWebViewConfiguration(),
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
        loadURL(SharedBundleInfo.webServerURL)
    }
    private func setBackgroundColor() {
        if webViewContainer.state == .loaded, isAuthenticated {
            view.backgroundColor = UIColor(red: 234 / 255, green: 234 / 255, blue: 234 / 255, alpha: 1)
        } else {
            view.backgroundColor = newsprint
        }
    }
    private func signIn(
        user: UserAccount,
        eventType: SignInEventType,
        completionHandler: ((_: NotificationAuthorizationStatus) -> Void)? = nil
    ) {
        os_log("[webapp] authenticated")
        // set authentication variable
        isAuthenticated = true
        // sync auth cookie from webview to shared storage
        webView.view.configuration.websiteDataStore.httpCookieStore.getAllCookies {
            cookies in
            if let authCookie = cookies.first(where: SharedCookieStore.authCookieMatchPredicate) {
                SharedCookieStore.setCookie(authCookie)
            }
        }
        // check notification settings
        UNUserNotificationCenter
            .current()
            .getNotificationSettings {
                settings in
                if settings.authorizationStatus == .authorized {
                    DispatchQueue.main.async {
                        NotificationService.syncBadge(with: user)
                    }
                }
                if let completionHandler = completionHandler {
                    // map system enum to our own since we're relying on
                    // the serialized numeric values being stable
                    let status: NotificationAuthorizationStatus
                    switch settings.authorizationStatus {
                    case .authorized:
                        status = .authorized
                    case .denied:
                        status = .denied
                    case .notDetermined:
                        status = .notDetermined
                    case.provisional:
                        status = .provisional
                    default:
                        status = .unknown
                    }
                    completionHandler(status)
                }
            }
        // set the background color
        setBackgroundColor()
    }
    private func signOut() {
        os_log("[webapp] unauthenticated")
        // set authentication variable
        isAuthenticated = false
        // clear auth cookie from shared storage
        SharedCookieStore.clearAuthCookies()
        // check notification settings
        UNUserNotificationCenter
            .current()
            .getNotificationSettings {
                settings in
                if settings.authorizationStatus == .authorized {
                    DispatchQueue.main.async {
                        NotificationService.clearAlerts()
                    }
                }
            }
        // set the background color
        setBackgroundColor()
    }
    @available(iOS 13.0, *)
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithAuthorization authorization: ASAuthorization
    ) {
        if let credential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let realUserStatusString: String
            switch (credential.realUserStatus) {
            case .likelyReal:
                realUserStatusString = "likelyReal"
            case .unsupported:
                realUserStatusString = "unsupported"
            case .unknown:
                fallthrough
            default:
                realUserStatusString = "unknown"
            }
            webView.sendMessage(
                message: Message(
                    type: "authenticateAppleIdCredential",
                    data: [
                        "authorizationCode": (
                            credential.authorizationCode != nil ?
                                String(
                                    data: credential.authorizationCode!,
                                    encoding: .utf8
                                ) :
                                nil
                        ),
                        "email": credential.email,
                        "identityToken": (
                            credential.identityToken != nil ?
                                String(
                                    data: credential.identityToken!,
                                    encoding: .utf8
                                ) :
                                nil
                        ),
                        "realUserStatus": realUserStatusString,
                        "user": credential.user
                    ]
                )
            )
        }
    }
    @available(iOS 13.0, *)
    func authorizationController(
        controller: ASAuthorizationController,
        didCompleteWithError error: Error
    ) {
        let errorMessage: String?
        if let authError = error as? ASAuthorizationError {
            switch (authError.code) {
            case .canceled:
                errorMessage = nil
            case .failed:
                errorMessage = "Authentication request failed."
            case .invalidResponse:
                errorMessage = "Invalid authentication response."
            case .notHandled:
                errorMessage = "Authentication request not handled."
            case .unknown:
                fallthrough
            default:
                errorMessage = "An unknown error occurred."
            }
        } else {
            errorMessage = error.localizedDescription
        }
        if let errorMessage = errorMessage {
            let alert = UIAlertController(
                title: "Error",
                message: errorMessage,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "Dismiss", style: .default))
            self.present(alert, animated: true)
        }
    }
    func loadURL(_ url: URL) {
        let preparedURL = prepareURL(url) ?? SharedBundleInfo.webServerURL
        os_log("[webapp] load url: %s", preparedURL.absoluteString)
        if hasEstablishedCommunication {
            webView.sendMessage(
                message: Message(
                    type: "loadUrl",
                    data: preparedURL
                )
            )
        } else {
            webView.view.load(
                URLRequest(
                    url: preparedURL
                )
            )
        }
        self.hasCalledWebViewLoad = true
    }
    override func loadView() {
        view = UIView()
        view.backgroundColor = newsprint
    }
    func onMessage(message: (type: String, data: Any?), callbackId: Int?) {
        switch message.type {
        case "getDeviceInfo":
            hasEstablishedCommunication = true
            webView.sendResponse(
                data: getDeviceInfo(),
                callbackId: callbackId!
            )
        case "initialize":
            hasEstablishedCommunication = true
            let initEvent = InitializationEvent(serializedEvent: message.data as! [String: Any])!
            if let user = initEvent.user {
                signIn(user: user, eventType: .existingUser)
            } else {
                signOut()
            }
            webView.sendResponse(
                data: getDeviceInfo(),
                callbackId: callbackId!
            )
        case "openExternalUrl":
            if let url = URL(string: message.data as! String) {
                presentSafariViewController(url: url, delegate: self)
            }
        case "readArticle":
            let data = message.data as! [String: Any]
            performSegue(
                withIdentifier: "readArticle",
                sender: data.keys.contains("url") ?
                    ArticleReference.url(URL(string: data["url"] as! String)!) :
                    ArticleReference.slug(data["slug"] as! String)
            )
        case "requestAppleIdCredential":
            if #available(iOS 13.0, *) {
                let appleIDProvider = ASAuthorizationAppleIDProvider()
                let request = appleIDProvider.createRequest()
                request.requestedScopes = [.email]
                
                let authorizationController = ASAuthorizationController(authorizationRequests: [request])
                authorizationController.delegate = self
                authorizationController.presentationContextProvider = self
                authorizationController.performRequests()
            } else {
                let alert = UIAlertController(
                    title: "Not Supported",
                    message: "iOS 13 or greater is required to use this feature.",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "Dismiss", style: .default))
                self.present(alert, animated: true)
            }
        case "requestNotificationAuthorization":
            UNUserNotificationCenter
                .current()
                .getNotificationSettings {
                    settings in
                    if settings.authorizationStatus == .notDetermined {
                        NotificationService.requestAuthorization() {
                            granted in
                            DispatchQueue.main.async {
                                self.webView.sendResponse(
                                    data: granted ?
                                        NotificationAuthorizationRequestResult.granted :
                                        NotificationAuthorizationRequestResult.denied,
                                    callbackId: callbackId!
                                )
                            }
                        }
                    } else {
                        let result: NotificationAuthorizationRequestResult
                        if settings.authorizationStatus == .authorized {
                            result = .previouslyGranted
                        } else {
                            result = .previouslyDenied
                        }
                        DispatchQueue.main.async {
                            self.webView.sendResponse(
                                data: result,
                                callbackId: callbackId!
                            )
                        }
                    }
                }
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
        case "signIn":
            let signInEvent = SignInEvent(serializedEvent: message.data as! [String: Any])!
            signIn(
                user: signInEvent.user,
                eventType: signInEvent.eventType,
                completionHandler: {
                    notificationAuthorizationStatus in
                    DispatchQueue.main.async {
                        self.webView.sendResponse(
                            data: SignInEventResponse(
                                notificationAuthorizationStatus: notificationAuthorizationStatus
                            ),
                            callbackId: callbackId!
                        )
                    }
                }
            )
        case "signOut":
            signOut()
        default:
            return
        }
    }
    func onStateChange(state: WebViewContainerState) {
        setBackgroundColor()
        if (state == .loading) {
            hasEstablishedCommunication = false
        }
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
                onArticlePosted: {
                    post in
                    self.webView.sendMessage(
                        message: Message(
                            type: "articlePosted",
                            data: post
                        )
                    )
                },
                onArticleUpdated: {
                    event in
                    self.webView.sendMessage(
                        message: Message(
                            type: "articleUpdated",
                            data: event
                        )
                    )
                },
                onAuthServiceAccountLinked: {
                    association in
                    self.webView.sendMessage(
                        message: Message(
                            type: "authServiceAccountLinked",
                            data: association
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
                },
                onCommentUpdated: {
                    comment in
                    self.webView.sendMessage(
                        message: Message(
                            type: "commentUpdated",
                            data: comment
                        )
                    )
                },
                onNavTo: {
                    url in
                    self.loadURL(url)
                }
            )
        }
    }
    @available(iOS 13.0, *)
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    @available(iOS 13.0, *)
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return view.window!
    }
    func readArticle(slug: String) {
        performSegue(
            withIdentifier: "readArticle",
            sender: ArticleReference.slug(slug)
        )
    }
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        dismiss(animated: true)
    }
    func signalDidBecomeActive(event: AppActivationEvent) {
        webView.sendMessage(
            message: Message(
                type: "didBecomeActive",
                data: event
            )
        )
    }
    func updateAlertStatus(_ status: AlertStatus) {
        webView.sendMessage(
            message: Message(
                type: "alertStatusUpdated",
                data: status
            )
        )
    }
    func updateDeviceInfo() {
        webView.sendMessage(
            message: Message(
                type: "deviceInfoUpdated",
                data: getDeviceInfo()
            )
        )
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // hide the navigation bar
        navigationController!.setNavigationBarHidden(true, animated: false)
        // force the navigation controller to light mode
        if #available(iOS 13.0, *) {
            navigationController!.overrideUserInterfaceStyle = .light
        }
        // disable swipe back gesture (window.webkit is undefined after beginning the gesture)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        // add the webview container as a subview
        view.addSubview(webViewContainer.view)
        webViewContainer.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            webViewContainer.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webViewContainer.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webViewContainer.view.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            webViewContainer.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        // check loading state
        if (!hasCalledWebViewLoad) {
            loadWebApp()
        }
    }
}
