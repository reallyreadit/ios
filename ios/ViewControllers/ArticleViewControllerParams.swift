import Foundation

struct ArticleViewControllerParams {
    let articleURL: URL
    let onClose: () -> Void
    let onReadStateCommitted: (_: ReadStateCommittedEvent) -> Void
}
