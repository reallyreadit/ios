import Foundation

struct CommentForm: Codable {
    init(_ data: [String: Any]) {
        text = data["text"] as! String
        articleId = data["articleId"] as! Int
        parentCommentId = data["parentCommentId"] as? String
    }
    let text: String
    let articleId: Int
    let parentCommentId: String?
}
