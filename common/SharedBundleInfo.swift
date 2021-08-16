import Foundation

struct SharedBundleInfo {
    public static let apiServerURL = URL(
        string: (Bundle.main.infoDictionary!["ReadupAPIServerURL"] as! String)
            .trimmingCharacters(in: ["/"])
    )!
    public static let authCookieDomain = Bundle.main.infoDictionary!["ReadupAuthCookieDomain"] as! String
    public static let authCookieName = Bundle.main.infoDictionary!["ReadupAuthCookieName"] as! String
    public static let clientID = Bundle.main.infoDictionary!["ReadupClientID"] as! String
    public static let shareExtensionScript = WebViewScript(
        bundledVersion: SemanticVersion(
            fromVersionString: Bundle.main.infoDictionary!["ReadupShareExtensionScriptVersion"] as? String
        )!,
        name: "share-extension"
    )
    public static let version = SemanticVersion(
        fromVersionString: (
            Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        )
    )!
    public static let webServerURL = URL(
        string: (Bundle.main.infoDictionary!["ReadupWebServerURL"] as! String)
            .trimmingCharacters(in: ["/"])
    )!
}
