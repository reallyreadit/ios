import Foundation

struct AppBundleInfo {
    public static let readerScript = WebViewScript(
        bundledVersion: SemanticVersion(
            fromVersionString: Bundle.main.infoDictionary!["RRITReaderScriptVersion"] as? String
        )!,
        name: "reader"
    )
    public static let staticContentServerURL = URL(
        string: (Bundle.main.infoDictionary!["RRITStaticContentServerURL"] as! String)
            .trimmingCharacters(in: ["/"])
    )!
    public static let webServerURL = URL(
        string: (Bundle.main.infoDictionary!["RRITWebServerURL"] as! String)
            .trimmingCharacters(in: ["/"])
    )!
}
