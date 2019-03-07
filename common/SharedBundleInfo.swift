import Foundation

struct SharedBundleInfo {
    public static let apiServerURL = URL(
        string: (Bundle.main.infoDictionary!["RRITAPIServerURL"] as! String)
            .trimmingCharacters(in: ["/"])
    )!
    public static let authCookieDomain = Bundle.main.infoDictionary!["RRITAuthCookieDomain"] as! String
    public static let authCookieName = Bundle.main.infoDictionary!["RRITAuthCookieName"] as! String
    public static let clientID = Bundle.main.infoDictionary!["RRITClientID"] as! String
    public static let debugReader = Bundle.main.infoDictionary!["RRITDebugReader"] as! Bool
    public static let version = SemanticVersion(
        fromVersionString: (
            (Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String) +
            "." +
            (Bundle.main.infoDictionary!["CFBundleVersion"] as! String)
        )
    )!
}
