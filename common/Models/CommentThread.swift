import Foundation

struct CommentThread: Codable {
    let id: String
    let dateCreated: Date
    let text: String
    let addenda: [CommentAddendum]
    let articleId: Int
    let articleTitle: String
    let articleSlug: String
    let userAccount: String
    let badge: LeaderboardBadge
    let parentCommentId: String?
    let dateDeleted: Date?
    let children: [CommentThread]
    let isAuthor: Bool
    let maxDate: Date
}
