import Foundation

struct CommentDeletionForm: Codable {
    init(_ data: [String: Any]) {
        commentId = data["commentId"] as! String
    }
    let commentId: String
}
