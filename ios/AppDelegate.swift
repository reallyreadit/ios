import UIKit
import UserNotifications
import os.log

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, NotificationServiceDelegate {
    
    var window: UIWindow?
    
    private let notificationService = NotificationService()
    
    private func getNaviationController() -> UINavigationController? {
        return window?.rootViewController as? UINavigationController
    }
    private func getWebAppViewController() -> WebAppViewController? {
        if let navigationController = getNaviationController() {
            return getWebAppViewController(
                navigationController: navigationController
            )
        }
        return nil
    }
    private func getWebAppViewController(
        navigationController: UINavigationController
    ) -> WebAppViewController? {
        return navigationController.viewControllers[0] as? WebAppViewController
    }
    private func loadURL(_ url: URL) -> Bool {
        if
            let navigationController = getNaviationController(),
            let webAppViewController = getWebAppViewController(
                navigationController: navigationController
            )
        {
            if (
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
                if navigationController.viewControllers.count == 1 {
                    webAppViewController.loadURL(commentsURL)
                    webAppViewController.readArticle(slug: slug)
                    return true
                } else if
                    navigationController.viewControllers.count == 2,
                    let articleViewController = navigationController.viewControllers[1] as? ArticleViewController
                {
                    webAppViewController.loadURL(commentsURL)
                    articleViewController.replaceArticle(slug: slug)
                    return true
                }
            } else {
                if navigationController.viewControllers.count > 1 {
                    navigationController.popToRootViewController(animated: true)
                }
                webAppViewController.loadURL(url)
                return true
            }
        }
        return false
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        // cleanup unused settings and files
        os_log("[lifecycle] didFinishLaunchingWithOptions")
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
            let referrerKey = "com.readup.nativeClientClipboardReferrer:"
            if
                let referrerString = UIPasteboard.general.strings?.first(where: {
                    string in string.starts(with: referrerKey)
                }),
                let jsonData = referrerString
                    .replacingOccurrences(of: referrerKey, with: "")
                    .data(using: .utf8)
            {
                let decoder = JSONDecoder.init()
                decoder.dateDecodingStrategy = .millisecondsSince1970
                if
                    let referrer = try? decoder.decode(ClipboardReferrer.self, from: jsonData),
                    var components = URLComponents(
                        url: (
                            referrer.timestamp.timeIntervalSinceNow > -30 * 60 ?
                                AppBundleInfo.webServerURL.appendingPathComponent(referrer.path) :
                                AppBundleInfo.webServerURL
                        ),
                        resolvingAgainstBaseURL: true
                    )
                {
                    
                    var queryItems = [URLQueryItem]()
                    if let marketingScreenVariant = referrer.marketingScreenVariant {
                        queryItems.append(
                            URLQueryItem(
                                name: "marketingScreenVariant",
                                value: String(marketingScreenVariant)
                            )
                        )
                    }
                    if let referrerURL = referrer.referrerURL {
                        queryItems.append(
                            URLQueryItem(
                                name: "referrerUrl",
                                value: referrerURL
                            )
                        )
                    }
                    if queryItems.count > 0 {
                        components.queryItems = queryItems
                    }
                    if let url = components.url {
                        let _ = loadURL(url)
                    }
                }
            }
        }
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
        if let webAppViewController = getWebAppViewController() {
            webAppViewController.signalDidBecomeActive(
                event: AppActivationEvent(
                    badgeCount: application.applicationIconBadgeNumber,
                    newStarCount: newStarCount
                )
            )
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        os_log("[lifecycle] willTerminate")
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
            if let webAppViewController = getWebAppViewController() {
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
        if let webAppViewController = getWebAppViewController() {
            webAppViewController.updateAlertStatus(status)
        }
    }
    
    func onViewNotification(url: URL) {
        let _ = loadURL(url)
    }
    
    func onViewSettings() {
        let _ = loadURL(AppBundleInfo.webServerURL.appendingPathComponent("/settings"))
    }

}

