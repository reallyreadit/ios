import Foundation

struct AppBundleInfo {
    public static let readerScriptVersion = SemanticVersion(
        fromVersionString: Bundle.main.infoDictionary!["RRITReaderScriptVersion"] as? String
    )!
    public static let shareExtensionScriptVersion = SemanticVersion(
        fromVersionString: Bundle.main.infoDictionary!["RRITShareExtensionScriptVersion"] as? String
    )!
    public static let staticContentServerURL = URL(
        string: (Bundle.main.infoDictionary!["RRITStaticContentServerURL"] as! String)
            .trimmingCharacters(in: ["/"])
    )!
    public static let webServerURL = URL(
        string: (Bundle.main.infoDictionary!["RRITWebServerURL"] as! String)
            .trimmingCharacters(in: ["/"])
    )!
}
