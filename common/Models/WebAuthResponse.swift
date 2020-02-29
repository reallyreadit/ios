import Foundation

struct WebAuthResponse : Codable {
    let callbackURL: URL?
    let error: String?
}
