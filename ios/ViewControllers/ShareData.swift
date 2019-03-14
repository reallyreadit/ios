import Foundation

struct ShareData: Codable {
    init(_ data: [String: Any]) {
        email = EmailShareData(data["email"] as! [String: Any])
        text = data["text"] as! String
        url = URL(string: data["url"] as! String)!
    }
    let email: EmailShareData
    let text: String
    let url: URL
}
