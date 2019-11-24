import Foundation

struct CommentAddendumForm: Codable {
    init(_ data: [String: Any]) {
        commentId = data["commentId"] as! String
        text = data["text"] as! String
    }
    let commentId: String
    let text: String
}
