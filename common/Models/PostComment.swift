import Foundation

struct PostComment: Codable {
    let id: String
    let text: String
    let addenda: [CommentAddendum]
}
