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

struct Article: Codable {
    let id: Int
    let title: String
    let slug: String
    let source: String
    let datePublished: Date?
    let section: String?
    let description: String?
    let aotdTimestamp: Date?
    let url: String
    let articleAuthors: [ArticleAuthor]
    let tags: [String]
    let wordCount: Int
    let commentCount: Int
    let readCount: Int
    let averageRatingScore: Double?
    let dateCreated: Date?
    let percentComplete: Double
    let isRead: Bool
    let dateStarred: Date?
    let ratingScore: Int?
    let datesPosted: [Date]
    let hotScore: Int
    let ratingCount: Int
    let firstPoster: String?
    let flair: ArticleFlair?
    let aotdContenderRank: Int
    let proofToken: String?
    let imageUrl: String?
}
