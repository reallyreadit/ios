// Copyright (C) 2022 reallyread.it, inc.
// 
// This file is part of Readup.
// 
// Readup is free software: you can redistribute it and/or modify it under the terms of the GNU Affero General Public License version 3 as published by the Free Software Foundation.
// 
// Readup is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.
// 
// You should have received a copy of the GNU Affero General Public License version 3 along with Foobar. If not, see <https://www.gnu.org/licenses/>.

enum WebViewResultType: Int, Encodable {
    case
        success = 1,
        failure = 2
}
struct WebViewResult<TSuccess: Encodable, TFailure: Error & Encodable>: Encodable{
    init(_ value: TSuccess) {
        self.type = .success
        self.value = value
        self.error = nil
    }
    init(_ error: TFailure) {
        self.type = .failure
        self.value = nil
        self.error = error
    }
    init(_ result: Result<TSuccess, TFailure>) {
        switch result {
        case .success(let value):
            self.init(value)
        case .failure(let error):
            self.init(error)
        }
    }
    let type: WebViewResultType
    let value: TSuccess?
    let error: TFailure?
}
