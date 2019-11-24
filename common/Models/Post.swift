import Foundation

struct Post: Codable {
    let date: Date
    let userName: String
    let badge: LeaderboardBadge
    let article: Article
    let comment: PostComment?
    let silentPostId: String?
    let dateDeleted: Date?
    let hasAlert: Bool
}
