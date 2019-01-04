import Foundation

struct CallEnvelope<T: Codable>: Codable {
    let callbackId: Int?
    let data: T
}
