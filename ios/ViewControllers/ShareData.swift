import Foundation

struct ShareData: Codable {
    init(_ data: [String: Any]) {
        body = data["body"] as? String
        subject = data["subject"] as? String
        url = URL(string: data["url"] as! String)!
    }
    let body: String?
    let subject: String?
    let url: URL
}
