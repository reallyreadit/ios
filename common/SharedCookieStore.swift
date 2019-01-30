import Foundation

private let apiServerURL = URL(string: Bundle.main.infoDictionary!["RRITAPIServerURL"] as! String)!
private let authCookieDomain = Bundle.main.infoDictionary!["RRITAuthCookieDomain"] as! String
private let authCookieName = Bundle.main.infoDictionary!["RRITAuthCookieName"] as! String
private func getAuthCookies() -> [HTTPCookie]? {
    return SharedCookieStore
        .store
        .cookies(for: apiServerURL)?
        .filter({ cookie in cookie.name == authCookieName })
}
struct SharedCookieStore {
    static let authCookieMatchPredicate: (_: HTTPCookie) -> Bool = {
        cookie in cookie.domain == authCookieDomain && cookie.name == authCookieName
    }
    static let store = HTTPCookieStorage.sharedCookieStorage(
        forGroupContainerIdentifier: "group.it.reallyread"
    )
    static func clearAuthCookies() {
        getAuthCookies()?.forEach({
            cookie in store.deleteCookie(cookie)
        })
    }
    static func isAuthenticated() -> Bool {
        return getAuthCookies()?.count ?? 0 > 0
    }
    static func setCookie(_ cookie: HTTPCookie) {
        store.setCookie(cookie)
    }
}
