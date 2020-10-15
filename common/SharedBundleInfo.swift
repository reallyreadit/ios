import Foundation

struct SharedBundleInfo {
    public static let apiServerURL = URL(
        string: (Bundle.main.infoDictionary!["RRITAPIServerURL"] as! String)
            .trimmingCharacters(in: ["/"])
    )!
    public static let authCookieDomain = Bundle.main.infoDictionary!["RRITAuthCookieDomain"] as! String
    public static let authCookieName = Bundle.main.infoDictionary!["RRITAuthCookieName"] as! String
    public static let clientID = Bundle.main.infoDictionary!["RRITClientID"] as! String
    public static let shareExtensionScript = WebViewScript(
        bundledVersion: SemanticVersion(
            fromVersionString: Bundle.main.infoDictionary!["RRITShareExtensionScriptVersion"] as? String
        )!,
        name: "share-extension"
    )
    public static let version = SemanticVersion(
        fromVersionString: (
            Bundle.main.infoDictionary!["CFBundleVersion"] as! String
        )
    )!
    public static let webServerURL = URL(
        string: (Bundle.main.infoDictionary!["RRITWebServerURL"] as! String)
            .trimmingCharacters(in: ["/"])
    )!
}
