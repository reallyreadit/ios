import Foundation

struct ArticleUpdatedEvent: Codable {
    let article: Article
    let isCompletionCommit: Bool
}
