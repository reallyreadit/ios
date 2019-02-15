import Foundation

struct ArticleRatingForm: Codable {
    init(_ data: [String: Any]) {
        articleId = data["articleId"] as! Int
        score = data["score"] as! Int
    }
    let articleId: Int
    let score: Int
}
