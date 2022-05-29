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

struct AlertStatus: Codable {
    init(serialized alertStatus: [String: Any]) {
        aotdAlert = alertStatus["aotdAlert"] as! Bool
        replyAlertCount = alertStatus["replyAlertCount"] as! Int
        loopbackAlertCount = alertStatus["loopbackAlertCount"] as! Int
        postAlertCount = alertStatus["postAlertCount"] as! Int
        followerAlertCount = alertStatus["followerAlertCount"] as! Int
    }
    let aotdAlert: Bool
    let replyAlertCount: Int
    let loopbackAlertCount: Int
    let postAlertCount: Int
    let followerAlertCount: Int
}
