import Foundation

struct UserPage: Codable {
    var id: Int
    var pageId: Int
    var userAccountId: Int
    var dateCreated: Date
    var lastModified: Date?
    var readableWordCount: Int
    var readState: [Int]
    var wordsRead: Int
    var dateCompleted: Date?
}
