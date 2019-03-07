import Foundation
import os.log

private let scripts = [
    Script(
        bundledVersion: AppBundleInfo.readerScriptVersion,
        name: "reader"
    ),
    Script(
        bundledVersion: AppBundleInfo.shareExtensionScriptVersion,
        name: "share-extension"
    )
]
struct ScriptUpdater {
    static func updateScripts() {
        let now = Date()
        let userDefaults = UserDefaults.init(suiteName: "group.it.reallyread")!
        for script in scripts {
            let lastUpdateCheckUserDefaultsKey = "scriptLastUpdateCheck:" + script.name
            let lastUpdateCheck = userDefaults.object(forKey: lastUpdateCheckUserDefaultsKey) as? Date
            os_log("ScriptUpdater: %s: %s", lastUpdateCheckUserDefaultsKey, lastUpdateCheck?.description ?? "nil")
            if lastUpdateCheck == nil || now.timeIntervalSince(lastUpdateCheck!) >= 4 * 60 * 60 {
                let currentVersionUserDefaultsKey = "scriptVersion:" + script.name
                let currentVersion = (
                    SemanticVersion(
                        fromVersionString: userDefaults.string(forKey: currentVersionUserDefaultsKey)
                    ) ??
                    script.bundledVersion
                )
                os_log("ScriptUpdater: checking latest version, current version: %s", currentVersion.description)
                URLSession
                    .shared
                    .dataTask(
                        with: AppBundleInfo.staticContentServerURL.appendingPathComponent("/native-client/\(script.name).txt"),
                        completionHandler: {
                            data, response, error in
                            if
                                error == nil,
                                let httpResponse = response as? HTTPURLResponse,
                                (200...299).contains(httpResponse.statusCode),
                                let data = data,
                                let text = String(data: data, encoding: .utf8)
                            {
                                userDefaults.set(now, forKey: lastUpdateCheckUserDefaultsKey)
                                if
                                    let newVersionFileName = text
                                        .split(separator: "\n")
                                        .first(where: {
                                            fileName in
                                            currentVersion.canUpgradeTo(SemanticVersion(fromFileName: String(fileName)))
                                        })
                                {
                                    URLSession.shared
                                        .dataTask(
                                            with: AppBundleInfo.staticContentServerURL.appendingPathComponent("/native-client/\(script.name)/\(newVersionFileName)"),
                                            completionHandler: {
                                                data, response, error in
                                                if
                                                    error == nil,
                                                    let httpResponse = response as? HTTPURLResponse,
                                                    (200...299).contains(httpResponse.statusCode),
                                                    let data = data,
                                                    let containerURL = FileManager.default.containerURL(
                                                        forSecurityApplicationGroupIdentifier: "group.it.reallyread"
                                                    )
                                                {
                                                    let newVersion = SemanticVersion(fromFileName: String(newVersionFileName))!
                                                    os_log("ScriptUpdater: upgrading to version %s", newVersion.description)
                                                    do {
                                                        try data.write(
                                                            to: containerURL.appendingPathComponent("\(script.name).js")
                                                        )
                                                        userDefaults.set(newVersion.description, forKey: currentVersionUserDefaultsKey)
                                                    }
                                                    catch let error {
                                                        os_log("ScriptUpdater: error saving file: %s", error.localizedDescription)
                                                    }
                                                } else {
                                                    os_log("ScriptUpdater: error downloading latest version")
                                                }
                                            }
                                        )
                                        .resume()
                                } else {
                                    os_log("ScriptUpdater: up to date")
                                }
                            } else {
                                os_log("ScriptUpdater: error checking latest version")
                            }
                        }
                    )
                    .resume()
            }
        }
    }
}
