import Foundation

struct ArticleViewControllerParams {
    let articleReference: ArticleReference
    let onArticleUpdated: (_: ArticleUpdatedEvent) -> Void
    let onClose: () -> Void
    let onCommentPosted: (_: CommentThread) -> Void
}
