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

enum ArticleReference: Encodable {
    init?(serializedReference: [String: Any]) {
        if serializedReference.keys.contains("url") {
            self = .url(URL(string: serializedReference["url"] as! String)!)
        } else {
            self = .slug(serializedReference["slug"] as! String)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch (self) {
        case .slug(let slug):
            try container.encode(slug, forKey: .slug)
        case .url(let url):
            try container.encode(url, forKey: .url)
        }
    }
    
    case slug(String)
    case url(URL)
    
    enum CodingKeys: CodingKey {
        case
            slug,
            url
    }
}
