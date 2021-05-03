import Foundation

struct Message<T: Encodable>: Encodable {
    let type: String
    let data: T
}
