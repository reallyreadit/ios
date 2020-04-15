import Foundation

class TempHTTPCookieStorage : HTTPCookieStorage {
    private var tempCookies: [HTTPCookie] = []
    override func getCookiesFor(
        _ task: URLSessionTask,
        completionHandler: @escaping ([HTTPCookie]?) -> Void
    ) {
        completionHandler(
            tempCookies.filter({
                cookie in
                task.currentRequest?.url?.host?.hasSuffix(cookie.domain.trimmingCharacters(in: ["."])) ?? false
            })
        )
    }
    override func storeCookies(
        _ cookies: [HTTPCookie],
        for task: URLSessionTask
    ) {
        tempCookies.append(contentsOf: cookies)
    }
}
