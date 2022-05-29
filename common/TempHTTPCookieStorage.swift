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
        storeCookies(cookies)
    }
    func storeCookies(
        _ cookies: [HTTPCookie]
    ) {
        tempCookies.append(contentsOf: cookies)
    }
}
