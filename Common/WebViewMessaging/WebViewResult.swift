enum WebViewResultType: Int, Encodable {
    case
        success = 1,
        failure = 2
}
struct WebViewResult<TSuccess: Encodable, TFailure: Error & Encodable>: Encodable{
    init(_ value: TSuccess) {
        self.type = .success
        self.value = value
        self.error = nil
    }
    init(_ error: TFailure) {
        self.type = .failure
        self.value = nil
        self.error = error
    }
    init(_ result: Result<TSuccess, TFailure>) {
        switch result {
        case .success(let value):
            self.init(value)
        case .failure(let error):
            self.init(error)
        }
    }
    let type: WebViewResultType
    let value: TSuccess?
    let error: TFailure?
}
