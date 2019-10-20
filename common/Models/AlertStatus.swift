import Foundation

struct AlertStatus: Codable {
    init(serialized alertStatus: [String: Any]) {
        aotdAlert = alertStatus["aotdAlert"] as! Bool
        replyAlertCount = alertStatus["replyAlertCount"] as! Int
        loopbackAlertCount = alertStatus["loopbackAlertCount"] as! Int
        postAlertCount = alertStatus["postAlertCount"] as! Int
        followerAlertCount = alertStatus["followerAlertCount"] as! Int
    }
    let aotdAlert: Bool
    let replyAlertCount: Int
    let loopbackAlertCount: Int
    let postAlertCount: Int
    let followerAlertCount: Int
}
