import Foundation

struct ArticleViewControllerParams {
    let article: ArticleViewControllerArticleParam
    let onClose: () -> Void
    let onReadStateCommitted: (_: ReadStateCommittedEvent) -> Void
}
