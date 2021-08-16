import Foundation
import OSLog

private struct ChromeExtensionAppManifest: Codable {
    let name: String
    let description: String
    let path: String
    let type: String
    let allowed_origins: [String]
}

private struct FirefoxExtensionAppManifest: Codable {
    let name: String
    let description: String
    let path: String
    let type: String
    let allowed_extensions: [String]
}

private let manifestFileName = "it.reallyread.mobile.browser_extension_app.json"
private let chromeManifestsPath = "Library/Application Support/Google/Chrome/NativeMessagingHosts/"
private let firefoxManifestsPath = "Library/Application Support/Mozilla/NativeMessagingHosts/"

private func getUnsandboxedHomeURL() -> URL? {
    guard let pw = getpwuid(getuid()) else {
        return nil
    }
    return URL(
        fileURLWithFileSystemRepresentation: pw.pointee.pw_dir,
        isDirectory: true,
        relativeTo: nil
    )
}
func writeBrowserExtensionAppManifests() {
    guard let homeURL = getUnsandboxedHomeURL() else {
        os_log("[browser-ext-app-manifest] Failed to get un-sandboxed home URL.")
        return
    }
    let manifestsPaths = [
        chromeManifestsPath,
        firefoxManifestsPath
    ]
    for manifestPath in manifestsPaths {
        let absoluteURL = homeURL.appendingPathComponent(manifestPath)
        if (!FileManager.default.fileExists(atPath: absoluteURL.path)) {
            do {
                try FileManager.default.createDirectory(
                    at: absoluteURL,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                os_log("[browser-ext-app-manifest] Created manifests directory: %s.", manifestPath)
            } catch {
                os_log("[browser-ext-app-manifest] Failed to create manifests directory: %s.", manifestPath)
            }
        }
    }
    guard let browserExtensionAppPath = Bundle.main.path(forAuxiliaryExecutable: "BrowserExtensionApp") else {
        os_log("[browser-ext-app-manifest] Failed to get BrowserExtensionApp executable path.")
        return
    }
    let encoder = JSONEncoder()
    if
        let chromeManifest = try? encoder.encode(
            ChromeExtensionAppManifest(
                name: "it.reallyread.mobile.browser_extension_app",
                description: "Readup Browser Extension App",
                path: browserExtensionAppPath,
                type: "stdio",
                allowed_origins: [
                    "chrome-extension://\(AppBundleInfo.chromeExtensionID)/"
                ]
            )
        )
    {
        do {
            try chromeManifest.write(
                to: homeURL
                    .appendingPathComponent(chromeManifestsPath)
                    .appendingPathComponent(manifestFileName)
            )
            os_log("[browser-ext-app-manifest] Wrote Chrome extension app manifest.")
        } catch {
            os_log("[browser-ext-app-manifest] Failed to write Chrome extension app manifest.")
        }
    } else {
        os_log("[browser-ext-app-manifest] Failed to encode Chrome extension app manifest.")
    }
    if
        let firefoxManifest = try? encoder.encode(
            FirefoxExtensionAppManifest(
                name: "it.reallyread.mobile.browser_extension_app",
                description: "Readup Browser Extension App",
                path: browserExtensionAppPath,
                type: "stdio",
                allowed_extensions: [
                    AppBundleInfo.firefoxExtensionID
                ]
            )
        )
    {
        do {
            try firefoxManifest.write(
                to: homeURL
                    .appendingPathComponent(firefoxManifestsPath)
                    .appendingPathComponent(manifestFileName)
            )
            os_log("[browser-ext-app-manifest] Wrote Firefox extension app manifest.")
        } catch {
            os_log("[browser-ext-app-manifest] Failed to write Firefox extension app manifest.")
        }
    } else {
        os_log("[browser-ext-app-manifest] Failed to encode Firefox extension app manifest.")
    }
}
