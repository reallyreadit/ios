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

struct CommentThread: Codable {
    let id: String
    let dateCreated: Date
    let text: String
    let addenda: [CommentAddendum]
    let articleId: Int
    let articleTitle: String
    let articleSlug: String
    let userAccount: String
    let badge: LeaderboardBadge
    let parentCommentId: String?
    let dateDeleted: Date?
    let children: [CommentThread]
    let isAuthor: Bool
    let maxDate: Date
}
