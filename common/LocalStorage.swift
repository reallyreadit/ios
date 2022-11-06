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
import UIKit

private enum LocalStorageKey: String {
    case appHasLaunched = "appHasLaunched"
    case displayPreference = "displayPreference"
    case domainMigrationHasCompleted = "domainMigrationHasCompleted"
    case extensionNewStarCount = "extensionNewStarCount"
    case notificationToken = "notificationToken"
    case notificationTokenSent = "notificationTokenSent"
    case scriptLastUpdateCheck = "scriptLastUpdateCheck:"
    case scriptDownloadedVersion = "scriptVersion:"
}
private let userDefaults = UserDefaults.init(suiteName: "group.it.reallyread")!
struct LocalStorage {
    static func clean() {
        userDefaults.removeObject(forKey: "contentScriptLastCheck")
        userDefaults.removeObject(forKey: "contentScriptVersion")
    }
    static func getDisplayPreference() -> DisplayPreference? {
        let decoder = JSONDecoder.init()
        if
            let encodedPreference = userDefaults.data(forKey: LocalStorageKey.displayPreference.rawValue),
            let preference = try? decoder.decode(DisplayPreference.self, from: encodedPreference)
        {
            return preference
        }
        return nil
    }
    static func getExtensionNewStarCount() -> Int {
        return userDefaults.integer(forKey: LocalStorageKey.extensionNewStarCount.rawValue)
    }
    static func getLastUpdateCheckForScript(name: String) -> Date? {
        return userDefaults.object(forKey: LocalStorageKey.scriptLastUpdateCheck.rawValue + name) as? Date
    }
    static func getNotificationToken() -> String? {
        return userDefaults.string(forKey: LocalStorageKey.notificationToken.rawValue)
    }
    static func getVersionForScript(name: String) -> SemanticVersion? {
        return SemanticVersion(
            fromVersionString: userDefaults.string(
                forKey: LocalStorageKey.scriptDownloadedVersion.rawValue + name
            )
        )
    }
    static func hasAppLaunched() -> Bool {
        return userDefaults.bool(forKey: LocalStorageKey.appHasLaunched.rawValue)
    }
    static func hasDomainMigrationCompleted() -> Bool {
        return userDefaults.bool(forKey: LocalStorageKey.domainMigrationHasCompleted.rawValue)
    }
    static func hasNotificationTokenBeenSent() -> Bool {
        return userDefaults.bool(forKey: LocalStorageKey.notificationTokenSent.rawValue)
    }
    static func registerDomainMigration() {
        userDefaults.set(true, forKey: LocalStorageKey.domainMigrationHasCompleted.rawValue)
    }
    static func registerInitialAppLaunch() {
        userDefaults.set(true, forKey: LocalStorageKey.appHasLaunched.rawValue)
    }
    static func removeDisplayPreference() {
        userDefaults.removeObject(forKey: LocalStorageKey.displayPreference.rawValue)
    }
    static func setDisplayPreference(preference: DisplayPreference) {
        let encoder = JSONEncoder.init()
        if let encodedPreference = try? encoder.encode(preference) {
            userDefaults.set(encodedPreference, forKey: LocalStorageKey.displayPreference.rawValue)
        }
    }
    static func setExtensionNewStarCount(count: Int) {
        userDefaults.set(count, forKey: LocalStorageKey.extensionNewStarCount.rawValue)
    }
    static func setLastUpdateCheckForScript(name: String, date: Date) {
        userDefaults.set(date, forKey: LocalStorageKey.scriptLastUpdateCheck.rawValue + name)
    }
    static func setNotificationToken(_ token: String) {
        userDefaults.set(token, forKey: LocalStorageKey.notificationToken.rawValue)
    }
    static func setNotificationTokenSent(_ sent: Bool) {
        userDefaults.set(sent, forKey: LocalStorageKey.notificationTokenSent.rawValue)
    }
    static func setVersionForScript(name: String, version: SemanticVersion) {
        userDefaults.set(version.description, forKey: LocalStorageKey.scriptDownloadedVersion.rawValue + name)
    }
}
