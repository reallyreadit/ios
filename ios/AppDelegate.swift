import UIKit
import os.log

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    private func updateContentScript() {
        let now = Date()
        let userDefaults = UserDefaults.init(suiteName: "group.it.reallyread")!
        let lastCheck = userDefaults.object(forKey: "contentScriptLastCheck") as? Date
        os_log("updateContentScript(): last checked: %s", lastCheck?.description ?? "nil")
        if lastCheck == nil || now.timeIntervalSince(lastCheck!) >= 1 * 60 * 60 {
            let currentVersion = userDefaults.double(forKey: "contentScriptVersion")
            os_log("updateContentScript(): checking latest version, current version: %f", currentVersion)
            URLSession
                .shared
                .dataTask(
                    with: URLRequest(
                        url: URL(
                            string: (
                                (Bundle.main.infoDictionary!["RRITWebServerURL"] as! String)
                                    .trimmingCharacters(in: ["/"]) +
                                "/assets/update/ContentScript.js?currentVersion=\(currentVersion)"
                            )
                        )!
                    ),
                    completionHandler: {
                        data, response, error in
                        if
                            error == nil,
                            let httpResponse = response as? HTTPURLResponse,
                            (200...299).contains(httpResponse.statusCode),
                            let data = data
                        {
                            userDefaults.set(now, forKey: "contentScriptLastCheck")
                            if
                                httpResponse.allHeaderFields.keys.contains("X-ReallyReadIt-Version"),
                                let newVersionString = httpResponse.allHeaderFields["X-ReallyReadIt-Version"] as? String,
                                let newVersion = Double(newVersionString),
                                let containerURL = FileManager.default.containerURL(
                                    forSecurityApplicationGroupIdentifier: "group.it.reallyread"
                                )
                            {
                                os_log("updateContentScript(): upgrading to version %f", newVersion)
                                do {
                                    try data.write(
                                        to: containerURL.appendingPathComponent("ContentScript.js")
                                    )
                                    userDefaults.set(newVersion, forKey: "contentScriptVersion")
                                }
                                catch let error {
                                    os_log("updateContentScript(): error saving file: %s", error.localizedDescription)
                                }
                            } else {
                                os_log("updateContentScript(): up to date")
                            }
                        } else {
                            os_log("updateContentScript(): error checking latest version")
                        }
                    }
                )
                .resume()
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }
    
    func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        if
            userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let url = userActivity.webpageURL,
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
                        with: "$1/articles/$2",
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
        updateContentScript()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

}

