import Foundation

struct TwitterCredentialLinkForm: Codable {
    init?(serializedForm: [String: Any]) {
        oauthToken = serializedForm["oauthToken"] as! String
        oauthVerifier = serializedForm["oauthVerifier"] as! String
    }
    let oauthToken: String
    let oauthVerifier: String
}
