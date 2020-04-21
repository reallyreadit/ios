import Foundation

private let clientHeaderValue = (
    SharedBundleInfo.clientID +
    "@" +
    SharedBundleInfo.version.description
)
private func createPostRequest(
    path: String
) -> URLRequest {
    var request = createRequest(url: createURL(fromPath: path))
    request.httpMethod = "POST"
    return request
}
private func createPostRequest<TData: Encodable>(
    path: String,
    data: TData?
) -> URLRequest {
    var request = createPostRequest(path: path)
    if data != nil {
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try! JSONEncoder().encode(data)
    }
    return request
}
private func createRequest(url: URL) -> URLRequest {
    var request = URLRequest(url: url)
    request.addValue(clientHeaderValue, forHTTPHeaderField: "X-Readup-Client")
    return request
}
private func createURL(fromPath path: String) -> URL {
    return SharedBundleInfo.apiServerURL.appendingPathComponent(path)
}
private func logError(
    _ request: URLRequest,
    _ response: URLResponse?,
    _ responseData: Data?,
    _ error: Error?
) {
    var content = "request debug description:\n" + request.debugDescription
    if
        let reqBody = request.httpBody,
        let reqBodyString = String(data: reqBody, encoding: .utf8)
    {
        content += "\n\nrequest body:\n" + reqBodyString
    }
    if let response = response {
        content += "\n\nresponse debug description:\n" + response.debugDescription
    }
    if
        let responseData = responseData,
        let responseString = String(data: responseData, encoding: .utf8)
    {
        content += "\n\nresponse body:\n" + responseString
    }
    if let error = error {
        content += "\n\nerror:\n" + error.localizedDescription
    }
    var logRequest = URLRequest(url: createURL(fromPath: "/Analytics/ClientErrorReport"))
    logRequest.httpMethod = "POST"
    logRequest.addValue(clientHeaderValue, forHTTPHeaderField: "X-Readup-Client")
    logRequest.addValue("text/plain", forHTTPHeaderField: "Content-Type")
    logRequest.httpBody = content.data(using: .utf8)
    URLSession.shared
        .dataTask(with: logRequest)
        .resume()
}
struct APIServerURLSession {
    private let urlSession: URLSession
    init() {
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = SharedCookieStore.getStore()
        urlSession = URLSession(configuration: config)
    }
    private func sendRequest(
        request: URLRequest,
        onSuccess: @escaping () -> Void,
        onError: @escaping (_: Error?) -> Void
    ) {
        urlSession
            .dataTask(
                with: request,
                completionHandler: {
                    (data, response, error) in
                    if
                        error == nil,
                        let httpResponse = response as? HTTPURLResponse,
                        (200...299).contains(httpResponse.statusCode)
                    {
                        onSuccess()
                    } else {
                        logError(request, response, data, error)
                        onError(error)
                    }
                }
            )
            .resume()
    }
    private func sendRequest<TResult: Decodable>(
        request: URLRequest,
        onSuccess: @escaping (_: TResult) -> Void,
        onError: @escaping (_: Error?) -> Void
    ) {
        urlSession
            .dataTask(
                with: request,
                completionHandler: {
                    (data, response, error) in
                    if
                        error == nil,
                        let httpResponse = response as? HTTPURLResponse,
                        (200...299).contains(httpResponse.statusCode),
                        let data = data
                    {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601DotNetCore
                        do {
                            let result = try decoder.decode(TResult.self, from: data)
                            onSuccess(result)
                        } catch let error {
                            logError(request, response, data, error)
                            onError(error)
                        }
                    } else {
                        logError(request, response, data, error)
                        onError(error)
                    }
                }
            )
            .resume()
    }
    func getJson<TResult: Decodable>(
        path: String,
        queryItems: URLQueryItem...,
        onSuccess: @escaping (_: TResult) -> Void,
        onError: @escaping (_: Error?) -> Void
    ) {
        var url = createURL(fromPath: path)
        if
            queryItems.count > 0,
            var components = URLComponents(url: url, resolvingAgainstBaseURL: true)
        {
            if components.queryItems == nil {
                components.queryItems = queryItems
            } else {
                components.queryItems!.append(contentsOf: queryItems)
            }
            url = components.url ?? url
        }
        sendRequest(
            request: createRequest(url: url),
            onSuccess: onSuccess,
            onError: onError
        )
    }
    func postJson<TData: Encodable>(
        path: String,
        data: TData?,
        onSuccess: @escaping () -> Void,
        onError: @escaping (_: Error?) -> Void
    ) {
        sendRequest(
            request: createPostRequest(
                path: path,
                data: data
            ),
            onSuccess: onSuccess,
            onError: onError
        )
    }
    func postJson<TResult: Decodable>(
        path: String,
        onSuccess: @escaping (_: TResult) -> Void,
        onError: @escaping (_: Error?) -> Void
    ) {
        sendRequest(
            request: createPostRequest(
                path: path
            ),
            onSuccess: onSuccess,
            onError: onError
        )
    }
    func postJson<TData: Encodable, TResult: Decodable>(
        path: String,
        data: TData?,
        onSuccess: @escaping (_: TResult) -> Void,
        onError: @escaping (_: Error?) -> Void
    ) {
        sendRequest(
            request: createPostRequest(
                path: path,
                data: data
            ),
            onSuccess: onSuccess,
            onError: onError
        )
    }
}
