import Foundation

enum NotificationAuthorizationRequestResult: Int, Codable {
    case
        none = 0,
        granted = 1,
        denied = 2,
        previouslyGranted = 3,
        previouslyDenied = 4
}
