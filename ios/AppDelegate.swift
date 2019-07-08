import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    private func loadURL(_ url: URL) -> Bool {
        if
            let navigationController = window?.rootViewController as? UINavigationController,
            let webAppViewController = navigationController.viewControllers[0] as? WebAppViewController
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
        let userDefaults = UserDefaults.init(suiteName: "group.it.reallyread")!
        userDefaults.removeObject(forKey: "contentScriptLastCheck")
        userDefaults.removeObject(forKey: "contentScriptVersion")
        let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: "group.it.reallyread"
        )!
        let oldContentScriptURL = containerURL.appendingPathComponent("ContentScript.js")
        if FileManager.default.isDeletableFile(atPath: oldContentScriptURL.absoluteString) {
            try! FileManager.default.removeItem(at: oldContentScriptURL)
        }
        // check for clipboard referrer
        let appHasLaunchedUserDefaultsKey = "appHasLaunched";
        if !userDefaults.bool(forKey: appHasLaunchedUserDefaultsKey) {
            userDefaults.set(true, forKey: appHasLaunchedUserDefaultsKey)
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
        return true
    }
    
    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
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
        return loadURL(url)
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        ScriptUpdater.updateScripts()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}

