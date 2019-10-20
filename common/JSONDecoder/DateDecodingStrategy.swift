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
