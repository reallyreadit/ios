import Foundation

struct ArticleIssueReportRequest: Codable {
    init(_ serializedRequest: [String: Any]) {
        articleId = serializedRequest["articleId"] as! Int
        issue = serializedRequest["issue"] as! String
    }
    let articleId: Int
    let issue: String
}
