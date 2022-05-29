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

struct ArticleParseResult: Codable {
    init(_ data: [String: Any]) {
        title = data["title"] as! String
        if let sourceData = data["source"] as? [String: Any] {
            source = SourceParseResult(sourceData)
        } else {
            source = nil
        }
        datePublished = data["datePublished"] as? String
        dateModified = data["dateModified"] as? String
        if
            let authorsData = data["authors"] as? [[String: Any]],
            authorsData.count > 0
        {
            authors = authorsData.map({ data in AuthorParseResult(data) })
        } else {
            authors = [AuthorParseResult]()
        }
        section = data["section"] as? String
        description = data["description"] as? String
        if
            let tagsData = data["tags"] as? [String],
            tagsData.count > 0
        {
            tags = tagsData
        } else {
            tags = [String]()
        }
        if
            let pageLinksData = data["pageLinks"] as? [[String: Any]],
            pageLinksData.count > 0
        {
            pageLinks = pageLinksData.map({ data in PageLinkParseResult(data) })
        } else {
            pageLinks = [PageLinkParseResult]()
        }
        imageUrl = data["imageUrl"] as? String
    }
    let title: String
    let source: SourceParseResult?
    let datePublished: String?
    let dateModified: String?
    let authors: [AuthorParseResult]
    let section: String?
    let description: String?
    let tags: [String]
    let pageLinks: [PageLinkParseResult]
    let imageUrl: String?
}
