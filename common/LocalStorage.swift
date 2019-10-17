import Foundation

private enum LocalStorageKey: String {
    case appHasLaunched = "appHasLaunched"
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
        userDefaults.removeObject(forKey: "domainMigrationHasCompleted")
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
    static func hasNotificationTokenBeenSent() -> Bool {
        return userDefaults.bool(forKey: LocalStorageKey.notificationTokenSent.rawValue)
    }
    static func registerInitialAppLaunch() {
        userDefaults.set(true, forKey: LocalStorageKey.appHasLaunched.rawValue)
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
