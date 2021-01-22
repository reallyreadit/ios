import Foundation

struct ResponseEnvelope<T: Encodable>: Encodable {
    let data: T
    let id: Int
}
