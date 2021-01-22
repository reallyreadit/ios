enum SubscriptionValidationResponseType: Int, Codable {
    case
        associatedWithCurrentUser = 1,
        associatedWithAnotherUser = 2,
        emptyReceipt = 3
}
struct SubscriptionValidationRequest: Encodable {
    let base64EncodedReceipt: String
}
struct SubscriptionValidationResponse: Codable {
    let type: SubscriptionValidationResponseType
    let subscriptionStatus: SubscriptionStatus?
    let subscribedUsername: String?
}
