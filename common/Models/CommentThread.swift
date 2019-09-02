import Foundation

struct CommentThread: Codable {
    let id: String
    let dateCreated: Date
    let text: String
    let articleId: Int
    let articleTitle: String
    let articleSlug: String
    let userAccount: String
    let badge: LeaderboardBadge
    let parentCommentId: String?
    let children: [CommentThread]
    let maxDate: Date
}
