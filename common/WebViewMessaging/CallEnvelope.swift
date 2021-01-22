import Foundation

struct CallEnvelope<T: Encodable>: Encodable {
    let callbackId: Int?
    let data: T
}
