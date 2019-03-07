import Foundation

private func getAuthCookies() -> [HTTPCookie]? {
    return SharedCookieStore
        .store
        .cookies(for: SharedBundleInfo.apiServerURL)?
        .filter({ cookie in cookie.name == SharedBundleInfo.authCookieName })
}
struct SharedCookieStore {
    static let authCookieMatchPredicate: (_: HTTPCookie) -> Bool = {
        cookie in cookie.domain == SharedBundleInfo.authCookieDomain && cookie.name == SharedBundleInfo.authCookieName
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
