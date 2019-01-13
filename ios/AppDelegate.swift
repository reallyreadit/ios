import UIKit
import os.log

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?

    private func updateContentScript() {
        let now = Date()
        let lastCheck = UserDefaults.standard.object(forKey: "contentScriptLastCheck") as? Date
        os_log(.debug, "updateContentScript(): last checked: %s", lastCheck?.description ?? "nil")
        if lastCheck == nil || now.timeIntervalSince(lastCheck!) >= 1 * 60 * 60 {
            let currentVersion = UserDefaults.standard.double(forKey: "contentScriptVersion")
            os_log(.debug, "updateContentScript(): checking latest version, current version: %f", currentVersion)
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
                            UserDefaults.standard.set(now, forKey: "contentScriptLastCheck")
                            if
                                httpResponse.allHeaderFields.keys.contains("X-ReallyReadIt-Version"),
                                let newVersionString = httpResponse.allHeaderFields["X-ReallyReadIt-Version"] as? String,
                                let newVersion = Double(newVersionString),
                                let appSupportDirURL = FileManager.default
                                    .urls(
                                        for: .applicationSupportDirectory,
                                        in: .userDomainMask
                                    )
                                    .first
                            {
                                os_log(.debug, "updateContentScript(): upgrading to version %f", newVersion)
                                let dirURL = appSupportDirURL.appendingPathComponent("reallyreadit")
                                if
                                    !FileManager.default.fileExists(
                                        atPath: dirURL.absoluteString
                                    )
                                {
                                    do {
                                        try FileManager.default.createDirectory(
                                            at: dirURL,
                                            withIntermediateDirectories: true
                                        )
                                    } catch let error {
                                        os_log(.debug, "updateContentScript(): error creating directory: %s", error.localizedDescription)
                                    }
                                }
                                do {
                                    try data.write(
                                        to: dirURL.appendingPathComponent("ContentScript.js")
                                    )
                                    UserDefaults.standard.set(newVersion, forKey: "contentScriptVersion")
                                }
                                catch let error {
                                    os_log(.debug, "updateContentScript(): error saving file: %s", error.localizedDescription)
                                }
                            } else {
                                os_log(.debug, "updateContentScript(): up to date")
                            }
                        } else {
                            os_log(.debug, "updateContentScript(): error checking latest version")
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
            if navigationController.viewControllers.count > 1 {
                navigationController.popToRootViewController(animated: true)
            }
            webAppViewController.loadURL(url)
            return true
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

