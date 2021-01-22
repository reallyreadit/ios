import StoreKit

struct SubscriptionProduct: Encodable {
    init(_ product: SKProduct) {
        let priceFormatter = NumberFormatter()
        priceFormatter.numberStyle = .currency
        priceFormatter.locale = product.priceLocale
        localizedDescription = product.localizedDescription
        localizedPrice = (
            priceFormatter.string(from: product.price) ??
            product.price.stringValue
        )
        localizedTitle = product.localizedTitle
        productId = product.productIdentifier
    }
    let localizedDescription: String
    let localizedPrice: String
    let localizedTitle: String
    let productId: String
}
struct SubscriptionProductsRequest {
    init(serializedRequest: [String: Any]) {
        productIds = serializedRequest["productIds"] as! [String]
    }
    let productIds: [String]
}

struct SubscriptionProductsResponse: Encodable {
    init(response: SKProductsResponse) {
        self.products = response.products.map({
            product in SubscriptionProduct(product)
        })
    }
    let products: [SubscriptionProduct]
}
