import Foundation

struct WebAuthRequest : Codable {
    init(serializedRequest: [String: Any]) {
        authURL = URL(
            string: serializedRequest["authUrl"] as! String
        )!
        callbackScheme = serializedRequest["callbackScheme"] as! String
    }
    let authURL: URL
    let callbackScheme: String
}
