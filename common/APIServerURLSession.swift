// Copyright (C) 2022 reallyread.it, inc.
// 
// This file is part of Readup.
// 
// Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
// 
// Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
// 
// You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

import Foundation

private let clientHeaderValue = (
    SharedBundleInfo.clientID +
    "@" +
    SharedBundleInfo.version.description
)
private func createGetRequest(
    path: String,
    queryItems: [URLQueryItem]
) -> URLRequest {
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
    return createRequest(url: url)
}
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
private func handleDataTaskError(
    _ request: URLRequest,
    _ data: Data?,
    _ response: URLResponse?,
    _ error: Error?,
    _ completionHandler: (_: Error?) -> Void
) {
    if
        let data = data,
        let httpResponse = response as? HTTPURLResponse,
        let contentType = httpResponse.allHeaderFields["Content-Type"] as? String,
        contentType.starts(with: "application/problem+json"),
        let problem = try? JSONDecoder().decode(HTTPProblemDetails.self, from: data)
    {
        completionHandler(problem)
    } else {
        logError(request, response, data, error)
        completionHandler(error)
    }
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
                        handleDataTaskError(request, data, response, error, onError)
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
                        handleDataTaskError(request, data, response, error, onError)
                    }
                }
            )
            .resume()
    }
    func getContent(
        path: String,
        queryItems: URLQueryItem...,
        onSuccess: @escaping (_: String) -> Void,
        onError: @escaping (_: Error?) -> Void
    ) {
        let request = createGetRequest(path: path, queryItems: queryItems)
        urlSession
            .dataTask(
                with: request,
                completionHandler: {
                    (data, response, error) in
                    if
                        error == nil,
                        let httpResponse = response as? HTTPURLResponse,
                        (200...299).contains(httpResponse.statusCode),
                        let data = data,
                        let content = String(data: data, encoding: .utf8)
                    {
                        onSuccess(content)
                    } else {
                        handleDataTaskError(request, data, response, error, onError)
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
        sendRequest(
            request: createGetRequest(path: path, queryItems: queryItems),
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
