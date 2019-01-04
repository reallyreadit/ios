import Foundation

extension JSONDecoder.DateDecodingStrategy {
    static let iso8601WithFractionalSeconds = custom {
        decoder in
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFractionalSeconds]
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)
        if let date = dateFormatter.date(from: stringValue) {
            return date
        }
        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "Invalid date: \(stringValue)"
        )
    }
}
