import Foundation

private func getAuthCookies(in store: HTTPCookieStorage) -> [HTTPCookie]? {
    return store
        .cookies(for: SharedBundleInfo.apiServerURL)?
        .filter({ cookie in cookie.name == SharedBundleInfo.authCookieName })
}
struct SharedCookieStore {
    static let authCookieMatchPredicate: (_: HTTPCookie) -> Bool = {
        cookie in cookie.domain == SharedBundleInfo.authCookieDomain && cookie.name == SharedBundleInfo.authCookieName
    }
    static func clearAuthCookies() {
        let store = getStore()
        getAuthCookies(in: store)?.forEach({
            cookie in store.deleteCookie(cookie)
        })
    }
    static func getStore() -> HTTPCookieStorage {
        return HTTPCookieStorage.sharedCookieStorage(
            forGroupContainerIdentifier: "group.it.reallyread"
        )
    }
    static func isAuthenticated() -> Bool {
        return getAuthCookies(in: getStore())?.count ?? 0 > 0
    }
    static func setCookie(_ cookie: HTTPCookie) {
        getStore().setCookie(cookie)
    }
}
