import Foundation

struct ReadStateCommittedEvent: Codable {
    let article: UserArticle
    let isCompletionCommit: Bool
}
