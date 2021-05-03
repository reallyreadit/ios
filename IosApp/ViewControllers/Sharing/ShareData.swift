import Foundation

struct ShareData: Codable {
    init(_ data: [String: Any]) {
        action = data["action"] as? String
        email = EmailShareData(data["email"] as! [String: Any])
        text = data["text"] as! String
        url = URL(string: data["url"] as! String)!
        selection = ShareSelection(data["selection"] as! [String: Any])
    }
    let action: String?
    let email: EmailShareData
    let text: String
    let url: URL
    let selection: ShareSelection
}
