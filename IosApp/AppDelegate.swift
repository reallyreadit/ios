import StoreKit
import UIKit
import UserNotifications
import os.log

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, NotificationServiceDelegate {
    
    var window: UIWindow?
    
    private let appReferralQueryStringKey = "appReferral"
    
    private let notificationService = NotificationService()
    
    private func checkForClipboardReferrer() {
        #if targetEnvironment(macCatalyst)
        os_log("[app-delegate] clipboard referrer not supported in mac catalyst")
        #else
        os_log("[app-delegate] checking UIPasteboard for referrer")
        if #available(iOS 14.0, *) {
            os_log("[app-delegate] querying UIPasteboard metadata for referrer")
            let webURLPattern = UIPasteboard.DetectionPattern.probableWebURL
            UIPasteboard.general.detectPatterns(
                for: [webURLPattern],
                completionHandler: {
                    result in
                    if
                        let patterns = try? result.get(),
                        patterns.contains(webURLPattern)
                    {
                        os_log("[app-delegate] UIPasteboard referrer probableWebURL detected")
                        UIPasteboard.general.detectValues(
                            for: [webURLPattern],
                            completionHandler: {
                                result in
                                if
                                    let values = try? result.get(),
                                    let urlString = values[webURLPattern] as? String
                                {
                                    self.processClipboardReferrer(urlString)
                                } else {
                                    os_log("[app-delegate] could not read UIPasteboard probableWebURL")
                                }
                            }
                        )
                    } else {
                        os_log("[app-delegate] UIPasteboard referrer probableWebURL not detected")
                    }
                }
            )
        } else {
            os_log("[app-delegate] reading UIPasteboard string for referrer")
            if
                let referrerString = UIPasteboard.general.strings?.first
            {
                processClipboardReferrer(referrerString)
            } else {
                os_log("[app-delegate] no UIPasteboard string found")
            }
        }
        #endif
    }
    
    private func processClipboardReferrer(_ referrerUrlString: String) {
        os_log("[app-delegate] attempting to process UIPasteboard referrer")
        let encoder = JSONEncoder.init()
        let decoder = JSONDecoder.init()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        if
            let referrerURL = URLComponents(string: referrerUrlString),
            (
                referrerURL.scheme == SharedBundleInfo.webServerURL.scheme &&
                referrerURL.host == SharedBundleInfo.webServerURL.host &&
                referrerURL.path == "/"
            ),
            let referrerQueryItem = referrerURL.queryItems?.first(
                where: {
                    queryItem in
                    queryItem.name == self.appReferralQueryStringKey
                }
            ),
            let referrerQueryValue = referrerQueryItem.value,
            let referrerQueryData = referrerQueryValue.data(using: .utf8),
            let referrer = try? decoder.decode(ClipboardReferrer.self, from: referrerQueryData),
            var components = URLComponents(
                url: (
                    referrer.timestamp.timeIntervalSinceNow > -30 * 60 ?
                        SharedBundleInfo.webServerURL.appendingPathComponent(referrer.currentPath) :
                        SharedBundleInfo.webServerURL
                ),
                resolvingAgainstBaseURL: true
            ),
            let appReferral = try? encoder.encode([
                "action": referrer.action,
                "initialPath": referrer.initialPath,
                "referrerUrl": referrer.referrerURL
            ])
        {
            os_log("[app-delegate] processed UIPasteboard referrer successfully")
            components.queryItems = [
                URLQueryItem(
                    name: appReferralQueryStringKey,
                    value: String(
                        data: appReferral,
                        encoding: .utf8
                    )
                )
            ]
            if let url = components.url {
                DispatchQueue.main.async {
                    let _ = self.loadURL(url)
                }
            }
        } else {
            os_log("[app-delegate] invalid UIPasteboard referrer")
        }
    }
    
    private func loadURL(_ url: URL) -> Bool {
        if
            let webAppViewController = window?.rootViewController as? WebAppViewController
        {
            if
                url.scheme == "readup",
                url.host == "read",
                let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true),
                let articleURLQueryItem = urlComponents.queryItems?.first(where: { $0.name == "url" }),
                let articleURL = URL(string: articleURLQueryItem.value ?? ""),
                SharedCookieStore.isAuthenticated()
            {
                let articleReference = ArticleReference.url(articleURL)
                let articleReadOptions = ArticleReadOptions(
                    star: urlComponents.queryItems?.contains(where: { $0.name == "star" }) ?? false
                )
                if webAppViewController.presentedViewController == nil {
                    os_log("[app-delegate] entering reader mode for article: %s", articleURL.absoluteString)
                    webAppViewController.readArticle(
                        reference: articleReference,
                        options: articleReadOptions
                    )
                    return true
                } else if
                    let articleViewController = webAppViewController.presentedViewController as? ArticleViewController
                {
                    os_log("[app-delegate] updating reader mode for article: %s", articleURL.absoluteString)
                    articleViewController.replaceArticle(
                        reference: articleReference,
                        options: articleReadOptions
                    )
                    return true
                }
            } else if (
                url.path.starts(with: "/read") &&
                url.pathComponents.count == 4 &&
                SharedCookieStore.isAuthenticated()
            ) {
                let slug = url.pathComponents[2] + "_" + url.pathComponents[3]
                let commentsURL = URL(
                    string: url.absoluteString.replacingOccurrences(
                        of: "^(https?://[^/]+)/read/(.+)",
                        with: "$1/comments/$2",
                        options: [.regularExpression, .caseInsensitive]
                    )
                )!
                if webAppViewController.presentedViewController == nil {
                    os_log("[app-delegate] entering reader mode for article: %s", slug)
                    webAppViewController.loadURL(commentsURL)
                    webAppViewController.readArticle(reference: .slug(slug))
                    return true
                } else if
                    let articleViewController = webAppViewController.presentedViewController as? ArticleViewController
                {
                    os_log("[app-delegate] updating reader mode for article: %s", slug)
                    webAppViewController.loadURL(commentsURL)
                    articleViewController.replaceArticle(reference: .slug(slug))
                    return true
                }
            } else {
                if webAppViewController.presentedViewController != nil {
                    os_log("[app-delegate] dismissing presented view controller")
                    webAppViewController.dismiss(animated: true)
                }
                os_log("[app-delegate] loading url: %s", url.absoluteString)
                webAppViewController.loadURL(url)
                return true
            }
        }
        return false
    }
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Override point for customization after application launch.
        os_log("[lifecycle] didFinishLaunchingWithOptions")
        // set up the view
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = WebAppViewController()
        window?.makeKeyAndVisible()
        // cleanup unused settings and files
        LocalStorage.clean()
        let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.it.reallyread"
        )!
        let oldContentScriptURL = containerURL.appendingPathComponent("ContentScript.js")
        if FileManager.default.isDeletableFile(atPath: oldContentScriptURL.absoluteString) {
            try! FileManager.default.removeItem(at: oldContentScriptURL)
        }
        // check for clipboard referrer on initial launch
        if !LocalStorage.hasAppLaunched() {
            LocalStorage.registerInitialAppLaunch()
            checkForClipboardReferrer()
        }
        // set up storekit observer
        SKPaymentQueue
            .default()
            .add(StoreService.shared)
        // set up notification delegates
        notificationService.delegate = self
        UNUserNotificationCenter.current().delegate = notificationService
        // register notification categories
        UNUserNotificationCenter
            .current()
            .setNotificationCategories([
                UNNotificationCategory(
                    identifier: NotificationService.replyableCategoryId,
                    actions: [
                        UNTextInputNotificationAction(
                            identifier: NotificationService.replyActionId,
                            title: "Reply",
                            options: []
                        )
                    ],
                    intentIdentifiers: [],
                    options: []
                )
            ])
        // check for new notification token
        UNUserNotificationCenter
            .current()
            .getNotificationSettings {
                settings in
                if settings.authorizationStatus == .authorized {
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }
        // check if notification token needs to be sent
        if
            !LocalStorage.hasNotificationTokenBeenSent(),
            let token = LocalStorage.getNotificationToken(),
            SharedCookieStore.isAuthenticated()
        {
            NotificationService.sendToken(token)
        }
        // macOS-specific initialization
        #if targetEnvironment(macCatalyst)
        // write the browser extension app manifests
        writeBrowserExtensionAppManifests()
        // On macOS applicationDidBecomeActive is only called during the initial launch and when the
        // window is restored from a hidden state. We're listening to AppKit events here in order to also
        // call applicationDidBecomeActive when the window is focused. In order to prevent duplicate events
        // the ignoreNextActivationEvent variable is set to true on launch and when the application is
        // hidden since we can expect applicationDidBecomeActive to be called in those circumstances.
        var ignoreNextActivationEvent = true
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NSApplicationDidHideNotification"),
            object: nil,
            queue: nil
        ) {
            _ in
            ignoreNextActivationEvent = true
        }
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NSApplicationDidBecomeActiveNotification"),
            object: nil,
            queue: nil
        ) {
            [weak self] _ in
            if ignoreNextActivationEvent {
                ignoreNextActivationEvent = false
                return
            }
            self?.applicationDidBecomeActive(UIApplication.shared)
        }
        #endif
        return true
    }
    
    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        os_log("[lifecycle] continue user activity")
        if
            userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let url = userActivity.webpageURL
        {
            return loadURL(url)
        }
        return false
    }
    
    func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey : Any] = [:]
    ) -> Bool {
        os_log("[lifecycle] open url")
        return loadURL(url)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        os_log("[lifecycle] willResignActive")
        StoreService.shared.cancelReceiptRequest()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        os_log("[lifecycle] didEnterBackground")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        os_log("[lifecycle] willEnterForeground")
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        os_log("[lifecycle] didBecomeActive")
        // update scripts
        ScriptUpdater.updateScripts()
        // update web app with new star count
        let newStarCount = LocalStorage.getExtensionNewStarCount()
        LocalStorage.setExtensionNewStarCount(count: 0)
        if let webAppViewController = window?.rootViewController as? WebAppViewController {
            webAppViewController.signalDidBecomeActive(
                event: AppActivationEvent(
                    badgeCount: application.applicationIconBadgeNumber,
                    newStarCount: newStarCount
                )
            )
        }
        // resume pending receipt request
        StoreService.shared.resumeReceiptRequest()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        os_log("[lifecycle] willTerminate")
        // remove storekit observer
        SKPaymentQueue
            .default()
            .remove(StoreService.shared)
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.reduce("", { $0 + String(format: "%02x", $1) })
        os_log("[notifications] registered with token: %s", token)
        if token != LocalStorage.getNotificationToken() {
            os_log("[notifications] token changed")
            // update local storage
            LocalStorage.setNotificationToken(token)
            LocalStorage.setNotificationTokenSent(false)
            // update web app
            if let webAppViewController = window?.rootViewController as? WebAppViewController {
                webAppViewController.updateDeviceInfo()
            }
            // send if authenticated
            if SharedCookieStore.isAuthenticated() {
                NotificationService.sendToken(token)
            }
        }
    }
    
    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        os_log("[notifications] registration error: %s", error.localizedDescription)
    }
    
    func onAlertStatusReceived(status: AlertStatus) {
        // update web app
        if let webAppViewController = window?.rootViewController as? WebAppViewController {
            webAppViewController.updateAlertStatus(status)
        }
    }
    
    func onViewNotification(url: URL) {
        let _ = loadURL(url)
    }
    
    func onViewSettings() {
        let _ = loadURL(SharedBundleInfo.webServerURL.appendingPathComponent("/settings"))
    }

}

