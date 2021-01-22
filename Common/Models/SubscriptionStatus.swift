import Foundation

enum SubscriptionStatusType: Int, Codable {
    case
        neverSubscribed = 1,
        incomplete = 2,
        active = 3,
        lapsed = 4
}
struct SubscriptionStatus: Codable {
    let type: SubscriptionStatusType
    let isUserFreeForLife: Bool
    let provider: SubscriptionProvider?
    let price: SubscriptionPrice?
    let requiresConfirmation: Bool?
    let currentPeriodBeginDate: Date?
    let currentPeriodEndDate: Date?
    let lastPeriodEndDate: Date?
}
