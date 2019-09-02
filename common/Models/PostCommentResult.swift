import Foundation

struct PostCommentResult: Codable {
    let article: Article
    let comment: CommentThread
}
