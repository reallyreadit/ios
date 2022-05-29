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

struct LeaderboardBadge: OptionSet, Codable {
    let rawValue: Int
    
    static let none = LeaderboardBadge([])
    static let longestRead = LeaderboardBadge(rawValue: 1 << 0)
    static let readCount = LeaderboardBadge(rawValue: 1 << 1)
    static let scout = LeaderboardBadge(rawValue: 1 << 2)
    static let scribe = LeaderboardBadge(rawValue: 1 << 3)
    static let streak = LeaderboardBadge(rawValue: 1 << 4)
    static let weeklyReadCount = LeaderboardBadge(rawValue: 1 << 5)
}
