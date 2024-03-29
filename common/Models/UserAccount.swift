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

struct UserAccount: Codable {
    init?(serializedUser: [String: Any]) {
        id = serializedUser["id"] as! Int
        name = serializedUser["name"] as! String
        email = serializedUser["email"] as! String
        dateCreated = parseDate(
            fromIso8601DotNetCoreString: serializedUser["dateCreated"] as! String
        )!
        role = UserAccountRole.init(rawValue: serializedUser["role"] as! Int)!
        timeZoneId = serializedUser["timeZoneId"] as? Int
        isEmailConfirmed = serializedUser["isEmailConfirmed"] as! Bool
        aotdAlert = serializedUser["aotdAlert"] as! Bool
        replyAlertCount = serializedUser["replyAlertCount"] as! Int
        loopbackAlertCount = serializedUser["loopbackAlertCount"] as! Int
        postAlertCount = serializedUser["postAlertCount"] as! Int
        followerAlertCount = serializedUser["followerAlertCount"] as! Int
        isPasswordSet = serializedUser["isPasswordSet"] as! Bool
        hasLinkedTwitterAccount = serializedUser["hasLinkedTwitterAccount"] as! Bool
    }
    let id: Int
    let name: String
    let email: String
    let dateCreated: Date
    let role: UserAccountRole
    let timeZoneId: Int?
    let isEmailConfirmed: Bool
    let aotdAlert: Bool
    let replyAlertCount: Int
    let loopbackAlertCount: Int
    let postAlertCount: Int
    let followerAlertCount: Int
    let isPasswordSet: Bool
    let hasLinkedTwitterAccount: Bool
}
