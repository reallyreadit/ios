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
    static func migrateAuthCookie() -> HTTPCookie? {
        if
            let legacyAuthCookie = getStore()
                .cookies(for: URL(string: "https://readup.com/")!)?
                .first(where: { cookie in cookie.name == SharedBundleInfo.authCookieName }),
            var cookieProperties = legacyAuthCookie.properties
        {
            cookieProperties[HTTPCookiePropertyKey.domain] = SharedBundleInfo.authCookieDomain
            if let newCookie = HTTPCookie(properties: cookieProperties) {
                setCookie(newCookie)
                return newCookie
            }
        }
        return nil
    }
    static func setCookie(_ cookie: HTTPCookie) {
        getStore().setCookie(cookie)
    }
}
