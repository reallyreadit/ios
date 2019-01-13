import Foundation

struct ResponseEnvelope<T: Codable>: Codable {
    let data: T
    let id: Int
}
