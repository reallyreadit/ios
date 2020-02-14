import Foundation

struct SignInEvent: Codable {
    init?(serializedEvent: [String: Any]) {
        user = UserAccount(serializedUser: serializedEvent["user"] as! [String: Any])!
        eventType = SignInEventType.init(rawValue: serializedEvent["eventType"] as! Int)!
    }
    let user: UserAccount
    let eventType: SignInEventType
}
