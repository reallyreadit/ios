import Foundation

struct APIServer {
    private static let urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = HTTPCookieStorage.sharedCookieStorage(
            forGroupContainerIdentifier: "group.it.reallyread"
        )
        return URLSession(configuration: config)
    }()
    static func postJson<TData: Encodable, TResult: Decodable>(
        path: String,
        data: TData?,
        onSuccess: @escaping (_: TResult) -> Void,
        onError: @escaping (_: Error?) -> Void
    ) {
        var request = URLRequest(
            url: URL(
                string: (Bundle.main.infoDictionary!["RRITAPIServerURL"] as! String)
                    .trimmingCharacters(in: ["/"]) + path
            )!
        )
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try! JSONEncoder().encode(data)
        APIServer.urlSession.dataTask(
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
                    decoder.dateDecodingStrategy = .iso8601WithFractionalSeconds
                    do {
                        let result = try decoder.decode(TResult.self, from: data)
                        onSuccess(result)
                    } catch let error {
                        onError(error)
                    }
                } else {
                    onError(error)
                }
            }
        )
        .resume()
    }
}
