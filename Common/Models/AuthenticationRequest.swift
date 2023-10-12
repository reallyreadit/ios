import Foundation

enum AuthenticationMethod: String, Codable {
    case
        createAccount = "createAccount",
        signIn = "signIn"
}

struct AuthenticationRequest: Codable {
    init(_ data: [String: Any]) {
        method = AuthenticationMethod.init(rawValue: data["method"] as! String)!
    }
    let method: AuthenticationMethod
}
