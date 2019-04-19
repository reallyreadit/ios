import Foundation

struct UserAccount: Codable {
    let id: Int
    let name: String
    let email: String
    let receiveReplyEmailNotifications: Bool
    let receiveReplyDesktopNotifications: Bool
    let lastNewReplyAck: Date
    let lastNewReplyDesktopNotification: Date
    let dateCreated: Date
    let role: UserAccountRole
    let receiveWebsiteUpdates: Bool
    let receiveSuggestedReadings: Bool
    let isEmailConfirmed: Bool
    let timeZoneId: Int?
    let timeZoneName: String?
    let timeZoneDisplayName: String?
}
