import Foundation

struct ArticleViewControllerParams {
    let articleReference: ArticleReference
    let onClose: () -> Void
    let onReadStateCommitted: (_: ReadStateCommittedEvent) -> Void
}
