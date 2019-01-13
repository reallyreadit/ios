import Foundation

struct ResponseCallback {
    let id: Int
    let function: (_: Any?) -> Void
}
