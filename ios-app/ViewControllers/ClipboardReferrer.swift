import Foundation

struct ClipboardReferrer: Codable {
    let action: String
    let currentPath: String
    let initialPath: String
    let marketingVariant: Int
    let referrerURL: String
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case action = "action"
        case currentPath = "currentPath"
        case initialPath = "initialPath"
        case marketingVariant = "marketingVariant"
        case referrerURL = "referrerUrl"
        case timestamp = "timestamp"
    }
}
