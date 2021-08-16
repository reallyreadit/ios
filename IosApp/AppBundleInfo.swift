import Foundation

struct AppBundleInfo {
    public static let chromeExtensionID = Bundle.main.infoDictionary!["ReadupChromeExtensionID"] as! String
    public static let firefoxExtensionID = Bundle.main.infoDictionary!["ReadupFirefoxExtensionID"] as! String
    public static let readerScript = WebViewScript(
        bundledVersion: SemanticVersion(
            fromVersionString: Bundle.main.infoDictionary!["ReadupReaderScriptVersion"] as? String
        )!,
        name: "reader"
    )
    public static let staticContentServerURL = URL(
        string: (Bundle.main.infoDictionary!["ReadupStaticContentServerURL"] as! String)
            .trimmingCharacters(in: ["/"])
    )!
}
