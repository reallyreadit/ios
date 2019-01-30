import Foundation

struct APIServer {
    private static let urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        config.httpCookieStorage = SharedCookieStore.store
        return URLSession(configuration: config)
    }()
    private static func createURL(fromPath path: String) -> URL {
        return URL(
            string: (Bundle.main.infoDictionary!["RRITAPIServerURL"] as! String)
                .trimmingCharacters(in: ["/"]) + path
        )!
    }
    private static func sendRequest<TResult: Decodable>(
        request: URLRequest,
        onSuccess: @escaping (_: TResult) -> Void,
        onError: @escaping (_: Error?) -> Void
    ) {
        urlSession.dataTask(
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
                        onError(error)
                    }
                } else {
                    onError(error)
                }
            }
        )
        .resume()
    }
    static func getJson<TResult: Decodable>(
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
            request: URLRequest(url: url),
            onSuccess: onSuccess,
            onError: onError
        )
    }
    static func postJson<TData: Encodable, TResult: Decodable>(
        path: String,
        data: TData?,
        onSuccess: @escaping (_: TResult) -> Void,
        onError: @escaping (_: Error?) -> Void
    ) {
        var request = URLRequest(url: createURL(fromPath: path))
        request.httpMethod = "POST"
        if data != nil {
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try! JSONEncoder().encode(data)
        }
        sendRequest(
            request: request,
            onSuccess: onSuccess,
            onError: onError
        )
    }
}
