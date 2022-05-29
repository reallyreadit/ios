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

func parseDate(fromIso8601DotNetCoreString value: String) -> Date? {
    return ISO8601DateFormatter().date(
        from: value.replacingOccurrences(
            of: "\\.\\d*$",
            with: "",
            options: [.regularExpression, .caseInsensitive]
        ) + "Z"
    )
}
extension JSONDecoder.DateDecodingStrategy {
    static let iso8601DotNetCore = custom {
        decoder in
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)
        if let date = parseDate(fromIso8601DotNetCoreString: stringValue) {
            return date
        }
        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Invalid date: \(stringValue)"
        )
    }
}
