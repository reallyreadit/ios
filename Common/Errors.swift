import Foundation

enum AppStoreErrorType: String {
    case
        paymentsDisallowed = "https://docs.readup.com/errors/app-store/payments-disallowed",
        productNotFound = "https://docs.readup.com/errors/app-store/product-not-found",
        purchaseCancelled = "https://docs.readup.com/errors/app-store/purchase-cancelled",
        receiptNotFound = "https://docs.readup.com/errors/app-store/receipt-not-found",
        receiptRequestFailed = "https://docs.readup.com/errors/app-store/receipt-request-failed"
}
enum BrowserExtensionAppErrorType: String {
    case
        messageParsingFailed = "https://docs.readup.com/errors/browser-extension-app/message-parsing-failed",
        readupProtocolFailed = "https://docs.readup.com/errors/browser-extension-app/readup-protocol-failed",
        unexpectedMessageType = "https://docs.readup.com/errors/browser-extension-app/unexpected-message-type"
}
enum GeneralErrorType: String {
    case
        exception = "https://docs.readup.com/errors/general/exception"
}
