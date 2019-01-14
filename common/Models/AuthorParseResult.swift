import Foundation

struct AuthorParseResult: Codable {
    init(_ data: [String: Any]) {
        name = data["name"] as! String
        url = data["url"] as? String
    }
    let name: String
    let url: String?
}
