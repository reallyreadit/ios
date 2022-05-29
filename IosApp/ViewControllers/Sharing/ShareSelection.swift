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

struct ShareSelection: Codable {
    init(_ data: [String: Any]) {
        x = data["x"] as! Double
        y = data["y"] as! Double
        width = data["width"] as! Double
        height = data["height"] as! Double
    }
    let x: Double
    let y: Double
    let width: Double
    let height: Double
}
