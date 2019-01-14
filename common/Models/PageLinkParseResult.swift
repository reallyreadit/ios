import Foundation

struct PageLinkParseResult: Codable {
    init(_ data: [String: Any]) {
        number = data["number"] as! Int
        url = data["url"] as! String
    }
    let number: Int
    let url: String
}
