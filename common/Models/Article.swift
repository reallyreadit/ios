import Foundation

struct Article: Codable {
    let id: Int
    let title: String
    let slug: String
    let source: String
    let datePublished: Date?
    let section: String?
    let description: String?
    let aotdTimestamp: Date?
    let url: String
    let authors: [String]
    let tags: [String]
    let wordCount: Int
    let commentCount: Int
    let readCount: Int
    let averageRatingScore: Double?
    let dateCreated: Date?
    let percentComplete: Double
    let isRead: Bool
    let dateStarred: Date?
    let ratingScore: Int?
    let datesPosted: [Date]
    let hotScore: Int
    let ratingCount: Int
    let firstPoster: String?
    let flair: ArticleFlair?
    let aotdContenderRank: Int
    let proofToken: String?
}
