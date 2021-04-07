import UIKit
import WebKit
import SafariServices
import os.log
import AuthenticationServices
import StoreKit

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
        // force https
        components.scheme = "https"
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
    UIViewControllerTransitioningDelegate,
    MessageWebViewDelegate,
    WebViewContainerDelegate,
    ASAuthorizationControllerDelegate,
    ASAuthorizationControllerPresentationContextProviding,
    ASWebAuthenticationPresentationContextProviding
{
    private var displayTheme: DisplayTheme!
    private var hasCalledWebViewLoad = false
    private var hasEstablishedCommunication = false
    private var webAuthSession: NSObject?
    private var webView: MessageWebView!
    private var webViewContainer: WebViewContainer!
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if displayTheme == .dark {
            return .lightContent
        }
        if #available(iOS 13.0, *) {
            return .darkContent
        }
        return .default
    }
    init() {
        super.init(nibName: nil, bundle: nil)
        // set theme
        displayTheme = DisplayPreferenceService.resolveDisplayTheme(
            traits: traitCollection,
            preference: LocalStorage.getDisplayPreference()
        )
        // init webview
        webView = MessageWebView(
            webViewConfig: WKWebViewConfiguration(),
            javascriptListenerObject: "window.reallyreadit.app"
        )
        webView.delegate = self
        webViewContainer = WebViewContainer(webView: webView.view)
        webViewContainer.delegate = self
        // configure webview
        webView.view.scrollView.bounces = false
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
        reloadButton.setTitleColor(.systemBlue, for: .normal)
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
        // theme webview
        webViewContainer.setDisplayTheme(theme: displayTheme)
        // register as store service delegate
        StoreService.shared.delegate = self
    }
    required init?(coder: NSCoder) {
        return nil
    }
    @objc private func loadWebApp() {
        loadURL(SharedBundleInfo.webServerURL)
    }
    private func signIn(
        user: UserAccount,
        eventType: SignInEventType,
        completionHandler: ((_: NotificationAuthorizationStatus) -> Void)? = nil
    ) {
        os_log("[webapp] authenticated")
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
    }
    private func signOut() {
        os_log("[webapp] unauthenticated")
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
        // clear display preference
        LocalStorage.removeDisplayPreference()
        updateDisplayPreference(preference: nil)
    }
    private func updateDisplayPreference(preference: DisplayPreference?) {
        displayTheme = DisplayPreferenceService.resolveDisplayTheme(traits: traitCollection, preference: preference)
        setNeedsStatusBarAppearanceUpdate()
        webViewContainer.setDisplayTheme(theme: displayTheme)
    }
    func animationController(
        forDismissed dismissed: UIViewController
    ) -> UIViewControllerAnimatedTransitioning?
    {
        return FadeOutAnimator(theme: displayTheme)
    }

    func animationController(
      forPresented presented: UIViewController,
      presenting: UIViewController, source: UIViewController
    ) -> UIViewControllerAnimatedTransitioning?
    {
        return FadeInAnimator(theme: displayTheme)
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
        view = webViewContainer.view
    }
    func onMessage(message: (type: String, data: Any?), callbackId: Int?) {
        switch message.type {
        case "displayPreferenceChanged":
            let preference = DisplayPreference(serializedPreference: message.data as! [String: Any])!
            LocalStorage.setDisplayPreference(preference: preference)
            updateDisplayPreference(preference: preference)
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
                presentSafariViewController(url: url, theme: displayTheme)
            }
        case "openExternalUrlUsingSystem":
            if let url = URL(string: message.data as! String) {
                UIApplication.shared.open(url)
            }
        case "readArticle":
            let data = message.data as! [String: Any]
            readArticle(
                reference: data.keys.contains("url") ?
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
        case "requestSubscriptionProducts":
            let request = SubscriptionProductsRequest(serializedRequest: message.data as! [String: Any])
            StoreService.shared.requestProducts(productIds: request.productIds) {
                result in
                DispatchQueue.main.async {
                    self.webView.sendResponse(
                        data: WebViewResult(
                            result.map({
                                response in SubscriptionProductsResponse(response: response)
                            })
                        ),
                        callbackId: callbackId!
                    )
                }
            }
        case "requestSubscriptionPurchase":
            let request = SubscriptionPurchaseRequest(serializedRequest: message.data as! [String: Any])
            self.webView.sendResponse(
                data: WebViewResult(
                    StoreService.shared
                        .purchase(productId: request.productId)
                        .map({
                            SubscriptionPurchaseResponse()
                        })
                ),
                callbackId: callbackId!
            )
        case "requestSubscriptionReceipt":
            StoreService.shared.requestReceipt() {
                result in
                DispatchQueue.main.async {
                    self.webView.sendResponse(
                        data: WebViewResult(
                            result.map({
                                receipt in SubscriptionReceiptResponse(base64EncodedReceipt: receipt)
                            })
                        ),
                        callbackId: callbackId!
                    )
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
        if (state == .loading) {
            hasEstablishedCommunication = false
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
    func readArticle(reference: ArticleReference) {
        let controller = ArticleViewController(
            params: ArticleViewControllerParams(
                articleReference: reference,
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
                    self.dismiss(animated: true)
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
                onDisplayPreferenceChanged: {
                    preference in
                    self.updateDisplayPreference(preference: preference)
                    self.webView.sendMessage(
                        message: Message(
                            type: "displayPreferenceChanged",
                            data: preference
                        )
                    )
                },
                onNavTo: {
                    url in
                    self.dismiss(animated: true)
                    self.loadURL(url)
                }
            )
        )
        // set view params
        controller.modalPresentationStyle = .custom
        controller.modalPresentationCapturesStatusBarAppearance = true
        controller.transitioningDelegate = self
        present(controller, animated: true)
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
        // check loading state
        if (!hasCalledWebViewLoad) {
            loadWebApp()
        }
    }
    override func viewDidAppear(_ animated: Bool) {
        // workaround for bug in WKWebView that causes it to appear under the titlebar
        // https://stackoverflow.com/questions/60728083/top-of-wkwebviewcontent-is-clipped-under-nstoolbar-in-mac-catalyst
        #if targetEnvironment(macCatalyst)
        guard let appBundleUrl = Bundle.main.builtInPlugInsURL else {
            return
        }
        let helperBundleUrl = appBundleUrl.appendingPathComponent("AppkitBridge.bundle")
        guard let bundle = Bundle(url: helperBundleUrl) else {
            return
        }
        bundle.load()
        guard let object = NSClassFromString("AppkitBridge") as? NSObject.Type else {
            return
        }
        let selector = NSSelectorFromString("removeFullSizeContentViewStyleMaskFromWindows")
        object.perform(selector)
        #endif
    }
}

extension WebAppViewController: StoreServiceDelegate {
    func transactionCompleted(result: Result<SubscriptionValidationResponse, ProblemDetails>) {
        DispatchQueue.main.async {
            self.webView.sendMessage(
                message: Message(
                    type: "subscriptionPurchaseCompleted",
                    data: WebViewResult(result)
                )
            )
        }
    }
}
