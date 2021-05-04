import StoreKit
import os.log

typealias ProductsRequestCompletionHandler = (_: Result<SKProductsResponse, ProblemDetails>) -> Void

private class ProductsRequest: NSObject, SKProductsRequestDelegate {
    private var completionHandler: ProductsRequestCompletionHandler?
    private var request: SKProductsRequest?
    @discardableResult init(
        productIds: [String],
        _ completionHandler: @escaping ProductsRequestCompletionHandler
    ) {
        super.init()
        // we need to create a strong reference cycle since SKProductsRequest does not
        self.completionHandler = {
            response in
            completionHandler(response)
            self.completionHandler = nil
        }
        // we also need to keep a strong reference to the request itself
        self.request = SKProductsRequest(
            productIdentifiers: Set(productIds)
        )
        self.request!.delegate = self
        self.request!.start()
    }
    func productsRequest(
        _ request: SKProductsRequest,
        didReceive response: SKProductsResponse
    ) {
        self.completionHandler?(
            .success(response)
        )
    }
    func request(
        _ request: SKRequest,
        didFailWithError error: Error
    ) {
        self.completionHandler?(
            .failure(
                ProblemDetails(error)
            )
        )
    }
}

// following the same pattern required for SKProductsRequest
typealias ReceiptRefreshRequestCompletionHandler = (_: Result<Void, Error>) -> Void

private class ReceiptRefreshRequest: NSObject, SKRequestDelegate {
    private var completionHandler: ReceiptRefreshRequestCompletionHandler?
    private var request: SKReceiptRefreshRequest?
    @discardableResult init(
        _ completionHandler: @escaping ReceiptRefreshRequestCompletionHandler
    ) {
        super.init()
        // we might need to create a strong reference cycle
        self.completionHandler = {
            response in
            completionHandler(response)
            self.completionHandler = nil
        }
        // we might also need to keep a strong reference to the request itself
        self.request = SKReceiptRefreshRequest()
        self.request!.delegate = self
        self.request!.start()
    }
    func requestDidFinish(_ request: SKRequest) {
        self.completionHandler?(
            .success(())
        )
    }
    func request(
        _ request: SKRequest,
        didFailWithError error: Error
    ) {
        self.completionHandler?(
            .failure(error)
        )
    }
}

protocol StoreServiceDelegate: AnyObject {
    func transactionCompleted(result: Result<SubscriptionValidationResponse, ProblemDetails>) -> Void
}

private func readLocalReceipt() -> Result<String, ProblemDetails> {
    guard let appStoreReceiptURL = Bundle.main.appStoreReceiptURL else {
        return .failure(
            ProblemDetails(
                type: AppStoreErrorType.receiptNotFound,
                title: "The receipt file could not be found."
            )
        )
    }
    do {
        let receiptData = try Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped)
        return .success(
            receiptData.base64EncodedString()
        )
    } catch {
        return .failure(
            ProblemDetails(error)
        )
    }
}

class StoreService: NSObject {
    private var products = [SKProduct]()
    static let shared = StoreService()
    weak var delegate: StoreServiceDelegate?
    private var queue = DispatchQueue(label: "it.reallyread.mobile.StoreService")
    private override init() {
        // singleton
    }
    func purchase(productId: String) -> Result<Void, ProblemDetails> {
        os_log("[store] purchasing product with id: %s", productId)
        if let product = self.products.first(
            where: { $0.productIdentifier == productId }
        ) {
            SKPaymentQueue
                .default()
                .add(
                    SKPayment(product: product)
                )
            return .success(())
        } else {
            return .failure(
                ProblemDetails(
                    type: AppStoreErrorType.productNotFound,
                    title: "Product not found."
                )
            )
        }
    }
    func requestProducts(
        productIds: [String],
        _ completionHandler: @escaping ProductsRequestCompletionHandler
    ) {
        os_log("[store] requesting products")
        if SKPaymentQueue.canMakePayments() {
            ProductsRequest(productIds: productIds) {
                result in
                if case .success(let response) = result {
                    self.products = response.products
                }
                completionHandler(result)
            }
        } else {
            completionHandler(
                .failure(
                    ProblemDetails(
                        type: AppStoreErrorType.paymentsDisallowed,
                        title: "The account that is signed in to the App Store cannot make payments."
                    )
                )
            )
        }
    }
    func requestReceipt(
        _ completionHandler: @escaping (_: Result<String, ProblemDetails>) -> Void
    ) {
        os_log("[store] requesting receipt")
        switch
            readLocalReceipt()
        {
        case .success(let receipt):
            os_log("[store] found local receipt")
            completionHandler(
                .success(receipt)
            )
        case .failure:
            os_log("[store] requesting new receipt from app store")
            ReceiptRefreshRequest() {
                refreshResult in
                switch refreshResult {
                case .success:
                    os_log("[store] request for new receipt from app store succeeded")
                    switch
                        readLocalReceipt()
                    {
                    case .success(let receipt):
                        os_log("[store] found local receipt after refresh")
                        completionHandler(
                            .success(receipt)
                        )
                    case .failure(let error):
                        os_log("[store] failed to read local receipt after refresh")
                        completionHandler(
                            .failure(error)
                        )
                    }
                case .failure(let error):
                        os_log("[store] failed to request new receipt from app store")
                        completionHandler(
                            .failure(
                                ProblemDetails(error)
                            )
                        )
                    }
                }
            }
        }
    }
}

extension StoreService: SKPaymentTransactionObserver {
    func paymentQueue(
        _ queue: SKPaymentQueue,
        updatedTransactions transactions: [SKPaymentTransaction]
    ) {
        for transaction in transactions {
            let description: String
            switch transaction.transactionState {
            case .deferred:
                description = "deferred"
            case .failed:
                description = "failed"
            case .purchased:
                description = "purchased"
            case .purchasing:
                description = "purchasing"
            case .restored:
                description = "restored"
            @unknown default:
                description = "unknown"
            }
            os_log(
                "[store] transaction updated. productId: %s, state: %s, transId: %s, originalId: %s, error: %s",
                transaction.payment.productIdentifier,
                description,
                transaction.transactionIdentifier ?? "N/A",
                transaction.original?.transactionIdentifier ?? "N/A",
                transaction.error?.localizedDescription ?? "N/A"
            )
            if transaction.transactionState == .purchased {
                requestReceipt() {
                    result in
                    switch result {
                    case .success(let receipt):
                        APIServerURLSession()
                            .postJson(
                                path: "/Subscriptions/AppleSubscriptionValidation",
                                data: SubscriptionValidationRequest(
                                    base64EncodedReceipt: receipt
                                ),
                                onSuccess: {
                                    (response: SubscriptionValidationResponse) in
                                    os_log("[store] subscription validated successfully")
                                    SKPaymentQueue
                                        .default()
                                        .finishTransaction(transaction)
                                    self.delegate?.transactionCompleted(
                                        result: .success(response)
                                    )
                                },
                                onError: {
                                    error in
                                    os_log("[store] failed to validate subscription")
                                    self.delegate?.transactionCompleted(
                                        result: .failure(
                                            ProblemDetails(
                                                type: SubscriptionsErrorType.receiptValidationFailed,
                                                title: "Receipt validation failed."
                                            )
                                        )
                                    )
                                }
                            )
                    case .failure:
                        self.delegate?.transactionCompleted(
                            result: .failure(
                                ProblemDetails(
                                    type: AppStoreErrorType.receiptRequestFailed,
                                    title: "Receipt request failed."
                                )
                            )
                        )
                    }
                }
            } else if transaction.transactionState == .failed {
                let problem: ProblemDetails
                let request: SubscriptionPurchaseFailureRequest
                if let skError = transaction.error as? SKError {
                    switch (skError.code) {
                    case .paymentCancelled:
                        problem = ProblemDetails(
                            type: AppStoreErrorType.purchaseCancelled,
                            title: "Purchase cancelled."
                        )
                    default:
                        problem = ProblemDetails(skError)
                    }
                    request = SubscriptionPurchaseFailureRequest(
                        code: skError.code.rawValue,
                        description: skError.localizedDescription
                    )
                } else {
                    let errorMessage = transaction.error?.localizedDescription ?? "Error not assigned."
                    problem = ProblemDetails(detail: errorMessage)
                    request = SubscriptionPurchaseFailureRequest(
                        code: nil,
                        description: errorMessage
                    )
                }
                APIServerURLSession()
                    .postJson(
                        path: "/Subscriptions/AppleSubscriptionPurchaseFailure",
                        data: request,
                        onSuccess: {
                            os_log("[store] registered failed transaction successfully")
                            SKPaymentQueue
                                .default()
                                .finishTransaction(transaction)
                        },
                        onError: {
                            error in
                            os_log("[store] failed to register failed transaction")
                        }
                    )
                self.delegate?.transactionCompleted(
                    result: .failure(problem)
                )
            }
        }
    }
}
