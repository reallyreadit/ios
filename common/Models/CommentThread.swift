import Foundation

struct CommentThread: Codable {
    let id: String
    let dateCreated: Date
    let text: String
    let articleId: Int
    let articleTitle: String
    let articleSlug: String
    let userAccount: String
    let parentCommentId: String?
    let dateRead: Date?
    let children: [CommentThread]
    let maxDate: Date
}
