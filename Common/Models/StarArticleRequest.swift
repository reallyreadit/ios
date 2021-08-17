import Foundation

struct StarArticleRequest: Codable {
    init(_ data: [String: Any]) {
        articleId = data["articleId"] as! Int
    }
    let articleId: Int
}
