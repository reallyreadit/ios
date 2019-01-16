import Foundation

extension JSONDecoder.DateDecodingStrategy {
    static let iso8601DotNetCore = custom {
        decoder in
        let dateFormatter = ISO8601DateFormatter()
        let container = try decoder.singleValueContainer()
        let stringValue = try container
            .decode(String.self)
            .replacingOccurrences(
                of: "\\.\\d*$",
                with: "",
                options: [.regularExpression, .caseInsensitive]
            ) + "Z"
        if let date = dateFormatter.date(from: stringValue) {
            return date
        }
        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Invalid date: \(stringValue)"
        )
    }
}
