import Foundation

struct EmailShareData: Codable {
    init(_ data: [String: Any]) {
        body = data["body"] as! String
        subject = data["subject"] as! String
    }
    let body: String
    let subject: String
}
