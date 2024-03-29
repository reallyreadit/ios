// Copyright (C) 2022 reallyread.it, inc.
// 
// This file is part of Readup.
// 
// Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
// 
// Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
// 
// You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

import Foundation
import os.log

struct ScriptUpdater {
    static func updateScripts() {
        let now = Date()
        for script in [AppBundleInfo.readerScript, SharedBundleInfo.shareExtensionScript] {
            let lastUpdateCheck = LocalStorage.getLastUpdateCheckForScript(name: script.name)
            os_log(
                "[scripts] last update check for %s: %s",
                script.name,
                lastUpdateCheck?.description ?? "nil"
            )
            if lastUpdateCheck == nil || now.timeIntervalSince(lastUpdateCheck!) >= 20 * 60 {
                let currentVersion = SemanticVersion.greatest(
                    script.bundledVersion,
                    LocalStorage.getVersionForScript(name: script.name)
                )
                os_log(
                    "[scripts] checking latest version for %s, current version: %s",
                    script.name,
                    currentVersion.description
                )
                URLSession
                    .shared
                    .dataTask(
                        with: AppBundleInfo.staticContentServerURL.appendingPathComponent(
                            "/native-client/\(script.name).txt"
                        ),
                        completionHandler: {
                            data, response, error in
                            if
                                error == nil,
                                let httpResponse = response as? HTTPURLResponse,
                                (200...299).contains(httpResponse.statusCode),
                                let data = data,
                                let text = String(data: data, encoding: .utf8)
                            {
                                LocalStorage.setLastUpdateCheckForScript(name: script.name, date: now)
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
                                            with: AppBundleInfo.staticContentServerURL.appendingPathComponent(
                                                "/native-client/\(script.name)/\(newVersionFileName)"
                                            ),
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
                                                    os_log(
                                                        "[scripts] upgrading %s to version %s",
                                                        script.name,
                                                        newVersion.description
                                                    )
                                                    do {
                                                        try data.write(
                                                            to: containerURL.appendingPathComponent(
                                                                "\(script.name).js"
                                                            )
                                                        )
                                                        LocalStorage.setVersionForScript(
                                                            name: script.name,
                                                            version: newVersion
                                                        )
                                                    }
                                                    catch let error {
                                                        os_log(
                                                            "[scripts] error saving file: %s",
                                                            error.localizedDescription
                                                        )
                                                    }
                                                } else {
                                                    os_log(
                                                        "[scripts] error downloading latest version of %s",
                                                        script.name
                                                    )
                                                }
                                            }
                                        )
                                        .resume()
                                } else {
                                    os_log("[scripts] %s up to date", script.name)
                                }
                            } else {
                                os_log("[scripts] error checking latest version of %s", script.name)
                            }
                        }
                    )
                    .resume()
            }
        }
    }
}
