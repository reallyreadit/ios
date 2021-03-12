import Foundation

enum SubscriptionStatusType: Int, Codable {
    case
        neverSubscribed = 1,
        paymentConfirmationRequired = 2,
        paymentFailed = 3,
        active = 4,
        lapsed = 5
}
struct SubscriptionStatus: Codable {
    let type: SubscriptionStatusType
    let isUserFreeForLife: Bool
    let provider: SubscriptionProvider?
    let price: SubscriptionPrice?
    let invoiceId: String?
    let currentPeriodBeginDate: Date?
    let currentPeriodEndDate: Date?
    let autoRenewEnabled: Bool?
    let autoRenewPrice: SubscriptionPrice?
    let lastPeriodEndDate: Date?
}
