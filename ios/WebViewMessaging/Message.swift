import Foundation

struct Message<T: Codable>: Codable {
    let type: String
    let data: T
}
