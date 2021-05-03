import Foundation

enum AppStoreErrorType: String {
    case
        paymentsDisallowed = "https://docs.readup.com/errors/app-store/payments-disallowed",
        productNotFound = "https://docs.readup.com/errors/app-store/product-not-found",
        purchaseCancelled = "https://docs.readup.com/errors/app-store/purchase-cancelled",
        receiptNotFound = "https://docs.readup.com/errors/app-store/receipt-not-found",
        receiptRequestFailed = "https://docs.readup.com/errors/app-store/receipt-request-failed"
}
enum GeneralErrorType: String {
    case
        exception = "https://docs.readup.com/errors/general/exception"
}
enum ReadingErrorType: String {
    case
        subscriptionRequired = "https://docs.readup.com/errors/reading/subscription-required"
}
enum SubscriptionsErrorType: String {
    case
        receiptValidationFailed = "https://docs.readup.com/errors/subscriptions/receipt-validation-failed"
}
