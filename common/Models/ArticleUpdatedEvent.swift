import Foundation

struct ArticleUpdatedEvent: Codable {
    let article: UserArticle
    let isCompletionCommit: Bool
}
