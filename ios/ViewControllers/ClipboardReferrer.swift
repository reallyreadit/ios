import Foundation

struct ClipboardReferrer: Codable {
    let marketingScreenVariant: Int?
    let path: String
    let referrerURL: String?
    let timestamp: Date
    
    enum CodingKeys: String, CodingKey {
        case marketingScreenVariant = "marketingScreenVariant"
        case path = "path"
        case referrerURL = "referrerUrl"
        case timestamp = "timestamp"
    }
}
