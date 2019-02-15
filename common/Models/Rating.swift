import Foundation

struct Rating: Codable {
    let id: Int
    let timestamp: Date
    let score: Int
    let articleId: Int
    let userAccountId: Int
}
