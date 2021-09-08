import Foundation

struct ArticleViewControllerParams {
    let articleReference: ArticleReference
    let onArticlePosted: (_: Post) -> Void
    let onArticleStarred: (_: ArticleStarredEvent) -> Void
    let onArticleUnstarred: (_: ArticleStarredEvent) -> Void
    let onArticleUpdated: (_: ArticleUpdatedEvent) -> Void
    let onAuthServiceAccountLinked: (_: AuthServiceAccountAssociation) -> Void
    let onClose: () -> Void
    let onCommentPosted: (_: CommentThread) -> Void
    let onCommentUpdated: (_: CommentThread) -> Void
    let onDisplayPreferenceChanged: (_: DisplayPreference) -> Void
    let onNavTo: (_: URL) -> Void
    let onOpenSubscriptionPrompt: () -> Void
}
