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

struct ShareData: Codable {
    init(_ data: [String: Any]) {
        action = data["action"] as? String
        email = EmailShareData(data["email"] as! [String: Any])
        text = data["text"] as! String
        url = URL(string: data["url"] as! String)!
        selection = ShareSelection(data["selection"] as! [String: Any])
    }
    let action: String?
    let email: EmailShareData
    let text: String
    let url: URL
    let selection: ShareSelection
}
