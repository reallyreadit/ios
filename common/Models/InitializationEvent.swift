import Foundation

struct InitializationEvent: Codable {
    init?(serializedEvent: [String: Any]) {
        if let serializedUser = serializedEvent["user"] as? [String: Any] {
            user = UserAccount(serializedUser: serializedUser)
        } else {
            user = nil
        }
    }
    let user: UserAccount?
}
