import Foundation

struct PostForm: Codable {
    init(_ data: [String: Any]) {
        articleId = data["articleId"] as! Int
        ratingScore = data["ratingScore"] as? Int
        commentText = data["commentText"] as? String
        tweet = data["tweet"] as! Bool
    }
    let articleId: Int
    let ratingScore: Int?
    let commentText: String?
    let tweet: Bool
}
