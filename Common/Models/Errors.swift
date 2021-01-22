enum ProductsRequestError: Int, Encodable, Error {
    case
        cannotMakePayments = 1
}
enum PurchaseError: Int, Encodable, Error {
    case
        productNotFound = 1
}
enum ReceiptRequestError: Int, Encodable, Error {
    case
        fileURLNotFound = 1
}
enum TransactionError: Int, Encodable, Error {
    case
        cancelled = 1,
        receiptRequestFailed = 2,
        subscriptionValidationFailed = 3
}
