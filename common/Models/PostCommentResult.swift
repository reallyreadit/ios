import Foundation

struct PostCommentResult: Codable {
    let article: UserArticle
    let comment: CommentThread
}
