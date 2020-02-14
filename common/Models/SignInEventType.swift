import Foundation

enum SignInEventType: Int, Codable {
    case
        newUser = 1,
        existingUser = 2
}
