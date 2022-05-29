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

struct PageParseResult: Codable {
    init(contentScriptData data: [String: Any], star: Bool = false) {
        url = data["url"] as! String
        number = data["number"] as? Int
        wordCount = data["wordCount"] as! Int
        readableWordCount = data["readableWordCount"] as! Int
        article = ArticleParseResult(data["article"] as! [String: Any])
        self.star = star
    }
    let url: String
    let number: Int?
    let wordCount: Int
    let readableWordCount: Int
    let article: ArticleParseResult
    let star: Bool
}
