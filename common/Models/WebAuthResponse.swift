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
import AuthenticationServices

struct WebAuthResponse : Codable {
    init(
        callbackURL: URL?,
        error: String?
    ) {
        self.callbackURL = callbackURL
        self.error = error
    }
    init(
        callbackURL: URL?,
        error: Error?
    ) {
        self.callbackURL = callbackURL
        let errorString: String?
        if let error = error {
            if
                #available(iOS 12.0, *),
                let authError = error as? ASWebAuthenticationSessionError
            {
                switch (authError.code) {
                case .canceledLogin:
                    errorString = "Cancelled"
                case .presentationContextInvalid:
                    errorString = "PresentationContextInvalid"
                case .presentationContextNotProvided:
                    errorString = "PresentationContextNotProvided"
                @unknown default:
                    errorString = "Unknown"
                }
            } else {
                errorString = "Unknown"
            }
        } else {
            errorString = nil
        }
        self.error = errorString
    }
    let callbackURL: URL?
    let error: String?
}
