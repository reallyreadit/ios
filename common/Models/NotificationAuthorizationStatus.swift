import Foundation

enum NotificationAuthorizationStatus: Int, Codable {
    case
        unknown = 0,
        notDetermined = 1,
        authorized = 2,
        denied = 3,
        provisional = 4
}
