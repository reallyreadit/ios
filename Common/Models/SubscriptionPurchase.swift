struct SubscriptionPurchaseRequest {
    init(serializedRequest: [String: Any]) {
        productId = serializedRequest["productId"] as! String
    }
    let productId: String
}
struct SubscriptionPurchaseResponse: Encodable {
    
}
