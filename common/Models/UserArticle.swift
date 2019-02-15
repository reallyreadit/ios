import Foundation

struct UserArticle: Codable {
    var id: Int
    var title: String
    var slug: String
    var source: String
    var datePublished: Date?
    var section: String?
    var description: String?
    var aotdTimestamp: Date?
    var url: String
    var authors: [String]
    var tags: [String]
    var wordCount: Int
    var commentCount: Int
    var readCount: Int
    var dateCreated: Date?
    var percentComplete: Double
    var isRead: Bool
    var dateStarred: Date?
    var ratingScore: Int?
    var proofToken: String?
}
